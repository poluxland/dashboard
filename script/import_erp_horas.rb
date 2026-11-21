require "pg"

source_url = ENV.fetch("ERP_HORAS_SOURCE_URL")
target_url = ENV.fetch("ERP_HORAS_TARGET_URL")
abort "Conecta bases distintas para origen y destino." if source_url == target_url

fields = %w[fecha descripcion area personal inicio termino he ot traslado lugar mandante estado ep created_at updated_at]
source_columns = ["id", *fields, "updated_at"].join(", ")
target_columns = ["erp_id", *fields, "erp_updated_at"].join(", ")
update_fields = (fields - ["created_at"] + ["erp_updated_at"]).map { |field| "#{field} = EXCLUDED.#{field}" }.join(", ")

PG.connect(source_url) do |source|
  PG.connect(target_url) do |target|
    result = source.transaction do
      source.exec("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY")
      target.transaction do
        target.exec("SELECT pg_advisory_xact_lock(20261120040000)")
        target.exec("CREATE TEMP TABLE erp_horas ON COMMIT DROP AS SELECT #{target_columns} FROM overtime_entries WITH NO DATA")

        source.copy_data("COPY (SELECT #{source_columns} FROM horas) TO STDOUT WITH (FORMAT csv)") do
          target.copy_data("COPY erp_horas (#{target_columns}) FROM STDIN WITH (FORMAT csv)") do
            while (row = source.get_copy_data)
              target.put_copy_data(row)
            end
          end
        end
        total = target.exec("SELECT count(*) FROM erp_horas").getvalue(0, 0).to_i
        raise "El ERP no devolvió horas." if total.zero?

        target.exec("LOCK TABLE overtime_entries IN SHARE ROW EXCLUSIVE MODE")
        mixed_edits = target.exec(<<~SQL).getvalue(0, 0).to_i
          SELECT count(*) FROM erp_horas AS source
          JOIN overtime_entries AS target USING (erp_id)
          WHERE source.erp_updated_at > target.erp_updated_at AND target.updated_at IS DISTINCT FROM target.erp_updated_at
        SQL
        raise "Hay #{mixed_edits} registros modificados en ambos sistemas. La carga se revirtió." if mixed_edits.positive?

        writes = target.exec(<<~SQL).cmd_tuples
          INSERT INTO overtime_entries (#{target_columns})
          SELECT #{target_columns} FROM erp_horas ORDER BY erp_id
          ON CONFLICT (erp_id) DO UPDATE SET #{update_fields}
          WHERE overtime_entries.updated_at = overtime_entries.erp_updated_at
            AND EXCLUDED.erp_updated_at > overtime_entries.erp_updated_at
        SQL
        preserved_edits = target.exec(<<~SQL).getvalue(0, 0).to_i
          SELECT count(*) FROM overtime_entries AS target
          JOIN erp_horas AS source USING (erp_id)
          WHERE target.updated_at IS DISTINCT FROM target.erp_updated_at
        SQL

        differences = target.exec(<<~SQL).getvalue(0, 0).to_i
          SELECT count(*) FROM (
            SELECT #{target_columns} FROM erp_horas
            WHERE erp_id NOT IN (
              SELECT erp_id FROM overtime_entries WHERE erp_id IS NOT NULL AND updated_at IS DISTINCT FROM erp_updated_at
            )
            EXCEPT
            SELECT #{target_columns} FROM overtime_entries
          ) AS differences
        SQL
        raise "Hay #{differences} filas que no coinciden con el ERP. La carga se revirtió." if differences.positive?

        [total, writes, preserved_edits]
      end
    end
    puts "ERP: #{result[0]} registros. Escritos: #{result[1]}. Editados en Dashboard y preservados: #{result[2]}. Diferencias sin explicar: 0."
  end
rescue PG::ConnectionBad
  abort "No se pudo conectar a una de las bases de datos."
end
