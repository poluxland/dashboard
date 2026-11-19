require "pg"

source_url = ENV.fetch("PMM_ESTADO_CANCHAS_SOURCE_URL")
target_url = ENV.fetch("PMM_ESTADO_CANCHAS_TARGET_URL")
abort "El origen y el destino deben ser distintos." if source_url == target_url

fields = %w[quilimari cachinales ñilhue caolin fierro puzolana tunga ceniza yeso conchuela san_pedro
            clinker_a clinker_b clinker_importado observaciones created_at updated_at].join(", ")
columns = "pmm_id, #{fields}"

totals = PG.connect(source_url) do |source|
  PG.connect(target_url) do |target|
    source.transaction do
      source.exec("SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY")
      target.transaction do
        target.exec("SELECT pg_advisory_xact_lock(20261119230000)")
        target.exec("CREATE TEMP TABLE pmm_cancha_snapshot ON COMMIT DROP AS SELECT * FROM estado_canchas WITH NO DATA")

        source.copy_data("COPY (SELECT id, #{fields} FROM estado_canchas) TO STDOUT WITH (FORMAT csv)") do
          target.copy_data("COPY pmm_cancha_snapshot (#{columns}) FROM STDIN WITH (FORMAT csv)") do
            while (row = source.get_copy_data)
              target.put_copy_data(row)
            end
          end
        end

        count = target.exec("SELECT count(*) FROM pmm_cancha_snapshot").getvalue(0, 0).to_i
        raise "La captura de PMM está vacía." if count.zero?

        inserted = target.exec(<<~SQL).cmd_tuples
          INSERT INTO estado_canchas (#{columns})
          SELECT #{columns} FROM pmm_cancha_snapshot ORDER BY pmm_id
          ON CONFLICT (pmm_id) DO NOTHING
        SQL
        differences = target.exec(<<~SQL).getvalue(0, 0).to_i
          SELECT count(*) FROM (
            SELECT #{columns} FROM pmm_cancha_snapshot
            EXCEPT
            SELECT #{columns} FROM estado_canchas
          ) AS differences
        SQL
        raise "La copia inicial no coincide con la captura de PMM." if inserted == count && differences.positive?

        [ count, inserted, differences ]
      end
    end
  end
end

puts "Registros en PMM: #{totals[0]}. Importados: #{totals[1]}. Diferencias: #{totals[2]}."
