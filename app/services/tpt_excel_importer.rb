require "roo"
require "digest"
require "bigdecimal"

class TptExcelImporter
  HEADERS = [ "Impacto", "Estado de producción", "Razón", "Hora de inicio", "% Hora",
              "Ocurrencias", "Total (s)", "Min (s)", "Promedio (s)", "Max (s)" ].freeze
  class InvalidSpreadsheet < StandardError; end

  def initialize(upload, author_email:)
    @upload = upload
    @author_email = author_email
  end

  def call
    workbook = load_workbook
    sheet = workbook.sheet(workbook.sheets.include?("Datos TPT") ? "Datos TPT" : 0)
    header_row = (1..[ sheet.last_row.to_i, 50 ].min).find do |number|
      sheet.row(number).first(10).map { |value| normalize(value) } == HEADERS.map { |value| normalize(value) }
    end
    raise InvalidSpreadsheet, "No se encontraron las 10 columnas del informe Datos TPT." unless header_row

    report = TptImport.new(filename: @upload.original_filename, author_email: @author_email)
    pending = {}
    detail_count = 0
    ((header_row + 1)..sheet.last_row.to_i).each do |number|
      row = sheet.row(number)
      next if row.all?(&:blank?)
      if row[3].blank?
        report.summary_count += 1
        next
      end

      detail_count += 1
      begin
        impact, state, reason = row.first(3).map { |value| value.to_s.strip }
        raise ArgumentError, "faltan impacto, estado o razón" if [ impact, state, reason ].any?(&:blank?)
        raise ArgumentError, "la fila no representa un evento individual" unless BigDecimal(row[5].to_s) == 1
        started_at = timestamp(sheet, number)
        duration = BigDecimal(row[6].to_s).round(6)
        raise ArgumentError, "duración inválida" unless duration.finite?
        fingerprint = Digest::SHA256.hexdigest([ impact, state, reason, started_at.iso8601(6) ].to_json)
        attributes = { impact: impact, production_state: state, reason: reason, started_at: started_at,
                       duration_seconds: duration, source_fingerprint: fingerprint, source_row: number }
        previous = pending[fingerprint]
        if previous
          record_duplicate(report, number, previous[:duration_seconds], duration)
        else
          pending[fingerprint] = attributes
        end
      rescue ArgumentError, TypeError => error
        report.issues << "Fila #{number}: #{error.message}."
      end
    end
    raise InvalidSpreadsheet, "El archivo no contiene eventos con Hora de inicio." if detail_count.zero?

    TptImport.transaction do
      # Serializa las cargas de esta máquina para comparar períodos superpuestos.
      TptImport.connection.execute("SELECT pg_advisory_xact_lock(74670801)")
      existing = TptEvent.where(source_fingerprint: pending.keys).pluck(:source_fingerprint, :duration_seconds).to_h
      new_rows = pending.reject do |fingerprint, attributes|
        next false unless existing.key?(fingerprint)
        record_duplicate(report, attributes[:source_row], existing[fingerprint], attributes[:duration_seconds])
        true
      end.values
      new_rows.select { |row| row[:duration_seconds].negative? }.each do |row|
        report.issues << "Fila #{row[:source_row]}: duración negativa conservada para revisión y excluida de las horas acumuladas."
      end
      report.imported_count = new_rows.length
      report.save!
      now = Time.current
      TptEvent.insert_all!(new_rows.map { |row| row.merge(tpt_import_id: report.id, created_at: now, updated_at: now) }) if new_rows.any?
    end
    report
  ensure
    workbook&.close
  end

  private

  def normalize(value)
    I18n.transliterate(value.to_s).downcase.gsub(/[^a-z0-9]/, "")
  end

  def load_workbook
    Roo::Excelx.new(@upload.tempfile.path)
  rescue StandardError
    raise InvalidSpreadsheet, "No se pudo leer el archivo XLSX."
  end

  def timestamp(sheet, number)
    value = sheet.cell(number, 4)
    # Roo trunca fracciones de segundo; recuperarlas del valor numérico original.
    raw = sheet.excelx_value(number, 4).to_s
    if sheet.celltype(number, 4) == :datetime && raw.match?(/\A\d+(?:\.\d+)?\z/)
      fraction = BigDecimal(raw).frac
      date = value.to_date
      Time.utc(date.year, date.month, date.day) + (fraction * 86_400).round(6).to_r
    else
      text = value.respond_to?(:strftime) ? value.strftime("%Y-%m-%d %H:%M:%S.%6N") : value.to_s.strip
      raise ArgumentError, "Hora de inicio debe ser una fecha Excel o AAAA-MM-DD HH:MM:SS" unless text.match?(/\A\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?\z/)
      DateTime.iso8601(text.tr(" ", "T")).to_time.utc
    end
  rescue Date::Error
    raise ArgumentError, "Hora de inicio inválida"
  end

  def record_duplicate(report, number, old_duration, new_duration)
    if old_duration == new_duration
      report.duplicate_count += 1
    else
      report.issues << "Fila #{number}: el evento ya existe con otra duración; se conserva el anterior."
    end
  end
end
