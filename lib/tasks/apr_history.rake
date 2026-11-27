namespace :apr do
  desc "Valida el histórico de Seguridad PTM; aplica la carga con APR_HISTORY_APPLY=1"
  task import_history: :environment do
    path = ENV.fetch("APR_HISTORY_FILE")
    apply = ENV["APR_HISTORY_APPLY"] == "1"
    result = AprHistoryImporter.new(path).call(apply: apply)
    puts "APR_HISTORY_RESULT #{result.merge(applied: apply).to_json}"
  end
end
