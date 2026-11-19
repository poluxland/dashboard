require "pg"

# Both connection strings are supplied through the environment.
source_url = ENV.fetch("ERP_EQUIPMENT_SOURCE_URL")
target_url = ENV.fetch("ERP_EQUIPMENT_TARGET_URL")
abort "La base de origen y la de destino deben ser distintas." if source_url == target_url

checks = (1..30).map { |number| "c#{number}" }
asset_columns = %w[erp_id code brand model plant year notes created_at updated_at].join(", ")
checklist_columns = (%w[erp_id legacy_code operator hour_meter] + checks + %w[comments created_at updated_at]).join(", ")

def copy_rows(source, target, query, table, columns)
  source.copy_data("COPY (#{query}) TO STDOUT WITH (FORMAT csv)") do
    target.copy_data("COPY #{table} (#{columns}) FROM STDIN WITH (FORMAT csv)") do
      while (row = source.get_copy_data)
        target.put_copy_data(row)
      end
    end
  end
end

PG.connect(source_url) do |source|
  PG.connect(target_url) do |target|
    source.transaction do
      source.exec("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY")
      target.transaction do
        target.exec("SELECT pg_advisory_xact_lock(20261119180000)")
        target.exec("CREATE TEMP TABLE erp_assets ON COMMIT DROP AS SELECT * FROM mobile_assets WITH NO DATA")
        target.exec("CREATE TEMP TABLE erp_checklists ON COMMIT DROP AS SELECT * FROM equipment_checklists WITH NO DATA")
        target.exec("ALTER TABLE erp_checklists ADD COLUMN source_truck_id bigint")

        copy_rows(source, target, 'SELECT id, codigo, marca, modelo, planta, "año", otros, created_at, updated_at FROM trucks',
                  "erp_assets", asset_columns)
        copy_rows(source, target,
                  "SELECT id, nombre, operador, horometro, #{checks.join(', ')}, comentarios, created_at, updated_at, truck_id FROM equipos",
                  "erp_checklists", "#{checklist_columns}, source_truck_id")

        assets = target.exec("SELECT count(*) FROM erp_assets").getvalue(0, 0).to_i
        checklists = target.exec("SELECT count(*) FROM erp_checklists").getvalue(0, 0).to_i
        raise "La captura del ERP está vacía." if assets.zero? || checklists.zero?

        inserted_assets = target.exec(<<~SQL).cmd_tuples
          INSERT INTO mobile_assets (#{asset_columns})
          SELECT #{asset_columns} FROM erp_assets ORDER BY erp_id
          ON CONFLICT (erp_id) DO NOTHING
        SQL
        target.exec(<<~SQL)
          UPDATE erp_checklists AS source
          SET mobile_asset_id = asset.id
          FROM mobile_assets AS asset
          WHERE asset.erp_id = source.source_truck_id
        SQL
        unresolved = target.exec("SELECT count(*) FROM erp_checklists WHERE source_truck_id IS NOT NULL AND mobile_asset_id IS NULL").getvalue(0, 0).to_i
        raise "Hay #{unresolved} referencias a equipos que no se pudieron importar." if unresolved.positive?

        inserted_checklists = target.exec(<<~SQL).cmd_tuples
          INSERT INTO equipment_checklists (#{checklist_columns}, mobile_asset_id)
          SELECT #{checklist_columns}, mobile_asset_id FROM erp_checklists ORDER BY erp_id
          ON CONFLICT (erp_id) DO NOTHING
        SQL

        asset_differences = target.exec(<<~SQL).getvalue(0, 0).to_i
          SELECT count(*) FROM (
            SELECT #{asset_columns} FROM erp_assets
            EXCEPT
            SELECT #{asset_columns} FROM mobile_assets
          ) AS differences
        SQL
        checklist_differences = target.exec(<<~SQL).getvalue(0, 0).to_i
          SELECT count(*) FROM (
            SELECT #{checklist_columns}, mobile_asset_id FROM erp_checklists
            EXCEPT
            SELECT #{checklist_columns}, mobile_asset_id FROM equipment_checklists
          ) AS differences
        SQL
        if (inserted_assets == assets && asset_differences.positive?) ||
           (inserted_checklists == checklists && checklist_differences.positive?)
          raise "La copia inicial no coincide con la captura del ERP."
        end

        puts "Equipos en origen: #{assets}. Nuevos: #{inserted_assets}. Diferencias: #{asset_differences}."
        puts "Checklists en origen: #{checklists}. Nuevos: #{inserted_checklists}. Diferencias: #{checklist_differences}."
      end
    end
  end
end
