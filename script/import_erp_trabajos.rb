require "pg"

source_url = ENV.fetch("ERP_TRABAJOS_SOURCE_URL")
target_url = ENV.fetch("ERP_TRABAJOS_TARGET_URL")
abort "La base de origen y la de destino deben ser distintas." if source_url == target_url

fields = %w[
  planta ito descripcion total fecha_termino avance op factura observaciones
  centro_costo supervisor otros detalle created_at updated_at
]
fields += (1..12).flat_map { |number| %w[i q v].map { |prefix| "#{prefix}#{number}" } }
source_columns = ([ "id" ] + fields).join(", ")
target_columns = ([ "erp_id" ] + fields).join(", ")

PG.connect(source_url) do |source|
  PG.connect(target_url) do |target|
    count, inserted = source.transaction do
      source.exec("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY")
      target.transaction do
        target.exec("SELECT pg_advisory_xact_lock(20261120000000)")
        target.exec("CREATE TEMP TABLE erp_trabajos ON COMMIT DROP AS SELECT #{target_columns} FROM trabajos WITH NO DATA")

        source.copy_data("COPY (SELECT #{source_columns} FROM trabajos) TO STDOUT WITH (FORMAT csv)") do
          target.copy_data("COPY erp_trabajos (#{target_columns}) FROM STDIN WITH (FORMAT csv)") do
            while (row = source.get_copy_data)
              target.put_copy_data(row)
            end
          end
        end

        count = target.exec("SELECT count(*) FROM erp_trabajos").getvalue(0, 0).to_i
        raise "El ERP no devolvió trabajos." if count.zero?

        inserted = target.exec(<<~SQL).cmd_tuples
          INSERT INTO trabajos (#{target_columns})
          SELECT #{target_columns} FROM erp_trabajos ORDER BY erp_id
          ON CONFLICT (erp_id) DO NOTHING
        SQL
        differences = target.exec(<<~SQL).getvalue(0, 0).to_i
          SELECT count(*) FROM (
            SELECT #{target_columns} FROM erp_trabajos
            EXCEPT
            SELECT #{target_columns} FROM trabajos WHERE erp_id IS NOT NULL
          ) AS differences
        SQL
        raise "Hay #{differences} trabajos distintos al ERP. La importación se revirtió." if differences.positive?

        [ count, inserted ]
      end
    end
    puts "ERP: #{count} trabajos. Nuevos: #{inserted}. Diferencias: 0."
  end
end
