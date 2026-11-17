require "base64"
require "zlib"
require "stringio"

namespace :ptm do
  desc "Corrige el histórico PTM conservando los valores originales"
  task correct_history: :environment do
    puts PtmHistoryCorrector.new.call.to_json
  end

  desc "Importación única PTM; JSON gzip/base64 por stdin, DRY_RUN=1 para revisar"
  task import: :environment do
    rows = JSON.parse(Zlib::GzipReader.new(StringIO.new(Base64.strict_decode64($stdin.gets.to_s.strip))).read)
    puts PtmHistoryImporter.new(rows).call(dry_run: ENV["DRY_RUN"] == "1").to_json
  end
end
