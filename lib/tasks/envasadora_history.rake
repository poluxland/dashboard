require "base64"
require "zlib"
require "stringio"

namespace :envasadora do
  desc "Carga cantidades diarias de calidad Haver (JSON gzip/base64 por stdin); DRY_RUN=1 valida sin guardar"
  task import_haver_quality: :environment do
    encoded = $stdin.gets
    raise "Faltan las cantidades de calidad Haver." if encoded.blank?
    payload = JSON.parse(Zlib::GzipReader.new(StringIO.new(Base64.strict_decode64(encoded.strip))).read)
    puts HaverQualityImporter.new(payload).call(dry_run: ENV["DRY_RUN"] == "1").to_json
  end

  desc "Importa el histórico preparado (JSON gzip/base64 por stdin); DRY_RUN=1 valida sin guardar"
  task import_history: :environment do
    encoded = $stdin.gets
    raise "Falta el histórico preparado por stdin." if encoded.blank?
    payload = JSON.parse(Zlib::GzipReader.new(StringIO.new(Base64.strict_decode64(encoded.strip))).read)
    importer = EnvasadoraHistoryImporter.new(payload)
    if ENV["DRY_RUN"] == "1"
      puts importer.prepare.to_json
    else
      puts importer.call(replace_test_record: payload["replace_test_record"]).to_json
    end
  end
end
