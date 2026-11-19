require "pg"

source_url = ENV.fetch("ERP_EQUIPMENT_SOURCE_URL")
target_url = ENV.fetch("ERP_EQUIPMENT_TARGET_URL")
abort "La base de origen y la de destino deben ser distintas." if source_url == target_url

kind = ARGV.first || "operator"
abort "Usa operator, maintenance o all." unless %w[operator maintenance all].include?(kind)

operator_checks = (1..30).map { |number| "c#{number}" }.join(", ")
maintenance_checks = (1..19).map { |number| "c#{number}" }.join(", ")

def copy_rows(source, target, query, table, columns)
  source.copy_data("COPY (#{query}) TO STDOUT WITH (FORMAT csv)") do
    target.copy_data("COPY #{table} (#{columns}) FROM STDIN WITH (FORMAT csv)") do
      while (row = source.get_copy_data)
        target.put_copy_data(row)
      end
    end
  end
end

def import_table(source, target, table:, columns:, query:, links_equipment: false)
  staging = "erp_#{table}"
  target.exec("CREATE TEMP TABLE #{staging} ON COMMIT DROP AS SELECT * FROM #{table} WITH NO DATA")
  if links_equipment
    target.exec("ALTER TABLE #{staging} ADD COLUMN source_truck_id bigint")
    copy_rows(source, target, query, staging, "#{columns}, source_truck_id")
    target.exec(<<~SQL)
      UPDATE #{staging} AS source
      SET mobile_asset_id = asset.id
      FROM mobile_assets AS asset
      WHERE asset.erp_id = source.source_truck_id
    SQL
    unresolved = target.exec("SELECT count(*) FROM #{staging} WHERE source_truck_id IS NOT NULL AND mobile_asset_id IS NULL").getvalue(0, 0).to_i
    raise "Hay #{unresolved} referencias a equipos sin correspondencia en #{table}." if unresolved.positive?
    columns += ", mobile_asset_id"
  else
    copy_rows(source, target, query, staging, columns)
  end

  count = target.exec("SELECT count(*) FROM #{staging}").getvalue(0, 0).to_i
  raise "La captura de #{table} está vacía." if count.zero?

  inserted = target.exec(<<~SQL).cmd_tuples
    INSERT INTO #{table} (#{columns})
    SELECT #{columns} FROM #{staging} ORDER BY erp_id
    ON CONFLICT (erp_id) DO NOTHING
  SQL
  differences = target.exec(<<~SQL).getvalue(0, 0).to_i
    SELECT count(*) FROM (
      SELECT #{columns} FROM #{staging}
      EXCEPT
      SELECT #{columns} FROM #{table}
    ) AS differences
  SQL
  raise "La copia inicial de #{table} no coincide con el ERP." if inserted == count && differences.positive?

  "#{table} en origen: #{count}. Nuevos: #{inserted}. Diferencias: #{differences}."
end

PG.connect(source_url) do |source|
  PG.connect(target_url) do |target|
    summary = []
    source.transaction do
      source.exec("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY")
      target.transaction do
        target.exec("SELECT pg_advisory_xact_lock(20261119180000)")
        summary << import_table(source, target, table: "mobile_assets",
          columns: "erp_id, code, brand, model, plant, year, notes, created_at, updated_at",
          query: 'SELECT id, codigo, marca, modelo, planta, "año", otros, created_at, updated_at FROM trucks')

        unless kind == "maintenance"
          summary << import_table(source, target, table: "equipment_checklists", links_equipment: true,
            columns: "erp_id, legacy_code, operator, hour_meter, #{operator_checks}, comments, created_at, updated_at",
            query: "SELECT id, nombre, operador, horometro, #{operator_checks}, comentarios, created_at, updated_at, truck_id FROM equipos")
        end

        unless kind == "operator"
          summary << import_table(source, target, table: "maintenance_checklists", links_equipment: true,
            columns: "erp_id, technician, legacy_code, operating_status, hour_meter, #{maintenance_checks}, " \
                     "fuel, engine_oil, hydraulic_oil, transmission_oil, atf_oil, nuto_oil, created_at, updated_at",
            query: "SELECT id, nombre, equipo, operativo, horometro, #{maintenance_checks}, " \
                   "combustible, acmotor, achidraulico, actrans, acatf, acnuto, created_at, updated_at, truck_id FROM checklists")
        end
      end
    end
    puts summary
  end
end
