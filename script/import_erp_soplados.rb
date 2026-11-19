require "pg"

source_url = ENV.fetch("ERP_SOPLADOS_SOURCE_URL")
target_url = ENV.fetch("ERP_SOPLADOS_TARGET_URL")
abort "La base de origen y la de destino deben ser distintas." if source_url == target_url

fields = %w[
  supervisor fecha presion1 presion2 presion3 presion4 presion5 presion6
  horno carbon_horno carbon_precalcinador jetin mirillas so3 tiempo operadores
  observaciones created_at updated_at
]
source_columns = ([ "id" ] + fields).join(", ")
target_columns = ([ "erp_id" ] + fields).join(", ")

begin
  PG.connect(source_url) do |source|
    PG.connect(target_url) do |target|
      count, inserted = source.transaction do
        source.exec("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY")
        target.transaction do
          target.exec("SELECT pg_advisory_xact_lock(20261120010000)")
          target.exec("CREATE TEMP TABLE erp_soplados ON COMMIT DROP AS SELECT #{target_columns} FROM soplados WITH NO DATA")

          source.copy_data("COPY (SELECT #{source_columns} FROM soplados) TO STDOUT WITH (FORMAT csv)") do
            target.copy_data("COPY erp_soplados (#{target_columns}) FROM STDIN WITH (FORMAT csv)") do
              while (row = source.get_copy_data)
                target.put_copy_data(row)
              end
            end
          end

          count = target.exec("SELECT count(*) FROM erp_soplados").getvalue(0, 0).to_i
          raise "El ERP no devolvió registros de soplado." if count.zero?

          inserted = target.exec(<<~SQL).cmd_tuples
            INSERT INTO soplados (#{target_columns})
            SELECT #{target_columns} FROM erp_soplados ORDER BY erp_id
            ON CONFLICT (erp_id) DO NOTHING
          SQL
          differences = target.exec(<<~SQL).getvalue(0, 0).to_i
            SELECT count(*) FROM (
              SELECT #{target_columns} FROM erp_soplados
              EXCEPT
              SELECT #{target_columns} FROM soplados WHERE erp_id IS NOT NULL
            ) AS differences
          SQL
          raise "Hay #{differences} registros distintos al ERP. La importación se revirtió." if differences.positive?

          [ count, inserted ]
        end
      end
      puts "ERP: #{count} registros de soplado. Nuevos: #{inserted}. Diferencias: 0."
    end
  end
rescue PG::ConnectionBad
  abort "No se pudo conectar a una de las bases de datos."
end
