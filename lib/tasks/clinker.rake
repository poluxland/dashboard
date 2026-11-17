namespace :clinker do
  desc "Carga inicial PTM del 9 al 14 de noviembre de 2026, sin reemplazar registros existentes"
  task import_initial: :environment do
    created = 0
    ClinkerTransfer.transaction do
      [ 1291, 943, 1236, 1377, 1551, 401 ].each_with_index do |tons, index|
        date = Date.new(2026, 11, 9) + index
        next if ClinkerTransfer.exists?(date: date)
        ClinkerTransfer.create!(date: date, tons: tons, author_email: "historico-clinker-ptm",
          observations: "Resumen semanal inicial proporcionado por el usuario.")
        created += 1
      end
    end
    puts({ created: created, total_tons: ClinkerTransfer.where(date: Date.new(2026, 11, 9)..Date.new(2026, 11, 14)).sum(:tons) }.to_json)
  end
end
