require "pg"

source_url = ENV.fetch("PMM_TRUCKS_SOURCE_URL")
target_url = ENV.fetch("PMM_TRUCKS_TARGET_URL")
abort "El origen y el destino deben ser distintos." if source_url == target_url

tables = {
  "pmm_materials" => [ "mmpps", %w[nombre descripcion densidad], false ],
  "pmm_yards" => [ "canchas", %w[nombre descripcion capacidad operativa], true ],
  "pmm_trucks" => [ "trucks", %w[fecha tipo llegada llamada salida patente wait cause motive number other], true ],
  "pmm_bru_visits" => [ "brus", %w[fecha ingreso salida patente mmpp comentarios numero], false ]
}.freeze

def copy_table(source, target, source_table, target_table, values, material_link)
  stage = "stage_#{target_table}"
  target.exec("CREATE TEMP TABLE #{stage} ON COMMIT DROP AS SELECT * FROM #{target_table} WITH NO DATA")
  fields = [ *values, "created_at", "updated_at" ]
  source_fields = [ "id", *fields, "updated_at" ]
  target_fields = [ "pmm_id", *fields, "pmm_updated_at" ]
  if material_link
    target.exec("ALTER TABLE #{stage} ADD COLUMN source_material_id bigint")
    source_fields << "mmpp_id"
    target_fields << "source_material_id"
  end

  source.copy_data("COPY (SELECT #{source_fields.join(', ')} FROM #{source_table}) TO STDOUT WITH (FORMAT csv)") do
    target.copy_data("COPY #{stage} (#{target_fields.join(', ')}) FROM STDIN WITH (FORMAT csv)") do
      while (row = source.get_copy_data)
        target.put_copy_data(row)
      end
    end
  end

  total = target.exec("SELECT count(*) FROM #{stage}").getvalue(0, 0).to_i
  raise "No hay registros de origen en #{source_table}." if total.zero?
  if material_link
    target.exec(<<~SQL)
      UPDATE #{stage} AS staged SET pmm_material_id = material.id
      FROM pmm_materials AS material
      WHERE staged.source_material_id = material.pmm_id
    SQL
    absent = target.exec("SELECT count(*) FROM #{stage} WHERE pmm_material_id IS NULL").getvalue(0, 0).to_i
    raise "Hay #{absent} materias primas sin correspondencia en #{source_table}." if absent.positive?

    target_fields[-1] = "pmm_material_id"
  end

  conflicts = target.exec(<<~SQL).getvalue(0, 0).to_i
    SELECT count(*) FROM #{stage} AS staged
    JOIN #{target_table} AS stored USING (pmm_id)
    WHERE staged.pmm_updated_at > stored.pmm_updated_at AND stored.updated_at IS DISTINCT FROM stored.pmm_updated_at
  SQL
  raise "Hay #{conflicts} registros de #{source_table} editados en ambos sistemas." if conflicts.positive?

  columns = target_fields.join(", ")
  update = (target_fields - %w[pmm_id created_at]).map { |field| "#{field} = EXCLUDED.#{field}" }.join(", ")
  writes = target.exec(<<~SQL).cmd_tuples
    INSERT INTO #{target_table} (#{columns}) SELECT #{columns} FROM #{stage} ORDER BY pmm_id
    ON CONFLICT (pmm_id) DO UPDATE SET #{update}
    WHERE EXCLUDED.pmm_updated_at > #{target_table}.pmm_updated_at
      AND #{target_table}.updated_at = #{target_table}.pmm_updated_at
  SQL

  differences = target.exec(<<~SQL).getvalue(0, 0).to_i
    SELECT count(*) FROM (
      SELECT #{columns} FROM #{stage}
      WHERE NOT EXISTS (
        SELECT 1 FROM #{target_table} AS local
        WHERE local.pmm_id = #{stage}.pmm_id AND local.updated_at IS DISTINCT FROM local.pmm_updated_at
      )
      EXCEPT SELECT #{columns} FROM #{target_table}
    ) AS differences
  SQL
  raise "Quedan #{differences} diferencias en #{source_table}. La importación se revirtió." if differences.positive?

  "#{source_table}: #{total} en PMM, #{writes} insertados o actualizados, #{differences} diferencias sin explicar."
end

begin
  results = PG.connect(source_url) do |source|
    PG.connect(target_url) do |target|
      source.transaction do
        source.exec("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY")
        target.transaction do
          target.exec("SELECT pg_advisory_xact_lock(20261120050000)")
          target.exec("LOCK TABLE #{tables.keys.join(', ')} IN SHARE ROW EXCLUSIVE MODE")
          tables.map do |target_table, (source_table, values, material_link)|
            copy_table(source, target, source_table, target_table, values, material_link)
          end
        end
      end
    end
  end
  puts results
rescue PG::ConnectionBad
  abort "No se pudo conectar a una de las bases."
end
