require "digest"
require "roo"
require "set"

class MantencionExcelImporter
  EXPECTED_HEADERS = [
    "Semana",
    "Fecha",
    "Tipo",
    "Área",
    "Código",
    "Tipo",
    "Actividad",
    "Planificación",
    "Estado",
    "N° OT",
    "Duracion",
    "Comentarios"
  ].freeze

  FINGERPRINT_FIELDS = %i[
    semana fecha especialidad area codigo tipo_mantencion actividad
    planificacion estado numero_ot duracion comentarios
  ].freeze

  Result = Struct.new(:created, :duplicates, :skipped, :corrected, :errors, keyword_init: true)
  class InvalidSpreadsheet < StandardError; end

  def initialize(uploaded_file)
    @uploaded_file = uploaded_file
  end

  def call
    sheet = load_sheet
    validate_headers!(sheet.row(1).first(EXPECTED_HEADERS.length))

    result = Result.new(created: 0, duplicates: 0, skipped: 0, corrected: 0, errors: [])
    known_fingerprints = existing_fingerprints
    pending_rows = []

    (2..sheet.last_row.to_i).each do |row_number|
      row = sheet.row(row_number).first(EXPECTED_HEADERS.length)

      if blank_data_row?(row)
        result.skipped += 1
        next
      end

      prepare_row(
        row,
        result,
        pending_rows,
        known_fingerprints,
        formatted_state: sheet.formatted_value(row_number, 9)
      )
    rescue ArgumentError, ActiveRecord::RecordInvalid => error
      result.errors << "Fila #{row_number}: #{error.message}"
    end

    insert_rows(pending_rows, result)
    result
  end

  private

  def load_sheet
    workbook = Roo::Excelx.new(@uploaded_file.tempfile.path)
    raise InvalidSpreadsheet, "El archivo no contiene hojas para importar." if workbook.sheets.empty?

    workbook.sheet(0)
  rescue InvalidSpreadsheet
    raise
  rescue StandardError => error
    raise InvalidSpreadsheet, "No se pudo leer el archivo XLSX: #{error.message}"
  end

  def validate_headers!(headers)
    normalized_headers = headers.map { |header| normalize_header(header) }
    expected_headers = EXPECTED_HEADERS.map { |header| normalize_header(header) }
    return if normalized_headers == expected_headers

    raise InvalidSpreadsheet,
          "Las columnas no corresponden al informe esperado. Deben estar en el orden: #{EXPECTED_HEADERS.join(', ')}."
  end

  def normalize_header(value)
    I18n.transliterate(value.to_s).downcase.gsub(/[^a-z0-9]/, "")
  end

  def blank_data_row?(row)
    meaningful_indexes = [ 0, 1, 3, 4, 5, 6, 7, 8, 9, 10, 11 ]
    meaningful_indexes.all? { |index| row[index].blank? }
  end

  def prepare_row(row, result, pending_rows, known_fingerprints, formatted_state:)
    fecha = date_value(row[1])
    attributes = {
      semana: week_value(row[0], fecha, result),
      fecha: fecha,
      especialidad: text_value(row[2]),
      area: text_value(row[3]),
      codigo: text_value(row[4]),
      tipo_mantencion: text_value(row[5]),
      actividad: text_value(row[6]),
      planificacion: text_value(row[7]),
      estado: percentage_value(row[8], formatted_value: formatted_state),
      numero_ot: text_value(row[9]),
      duracion: decimal_value(row[10]),
      comentarios: text_value(row[11])
    }

    record = Mantencion.new(attributes)
    raise ActiveRecord::RecordInvalid, record unless record.valid?

    normalized_attributes = FINGERPRINT_FIELDS.index_with { |field| record.public_send(field) }
    fingerprint = fingerprint_for(normalized_attributes)

    if known_fingerprints.include?(fingerprint)
      result.duplicates += 1
      return
    end

    record.source_fingerprint = fingerprint

    timestamp = Time.current
    pending_rows << record.attributes.symbolize_keys.slice(
      *FINGERPRINT_FIELDS,
      :source_fingerprint
    ).merge(created_at: timestamp, updated_at: timestamp)
    known_fingerprints << fingerprint
  end

  def existing_fingerprints
    Mantencion.find_each.each_with_object(Set.new) do |mantencion, fingerprints|
      attributes = FINGERPRINT_FIELDS.index_with { |field| mantencion.public_send(field) }
      fingerprints << fingerprint_for(attributes)
    end
  end

  def insert_rows(rows, result)
    return if rows.empty?

    inserted = Mantencion.insert_all(
      rows,
      unique_by: :index_mantenciones_on_source_fingerprint
    ).rows.size

    result.created += inserted
    result.duplicates += rows.size - inserted
  end

  def text_value(value)
    return if value.blank?
    return value.to_i.to_s if value.is_a?(Numeric) && value.to_f == value.to_i

    value.to_s.strip
  end

  def integer_value(value)
    return if value.blank?

    number = BigDecimal(value.to_s.tr(",", "."))
    raise ArgumentError, "#{value.inspect} debe ser un número entero" unless number.frac.zero?

    number.to_i
  end

  def week_value(value, date, result)
    week = integer_value(value)
    return date&.cweek if week.nil?
    return week if (1..53).cover?(week)

    result.corrected += 1
    date.cweek
  rescue ArgumentError
    raise if date.blank?

    result.corrected += 1
    date.cweek
  end

  def decimal_value(value)
    return if value.blank?

    BigDecimal(value.to_s.tr(",", "."))
  end

  def percentage_value(value, formatted_value: nil)
    return if value.blank?

    if value.is_a?(Numeric)
      formatted_text = formatted_value.to_s.strip
      return BigDecimal(formatted_text.delete("%").strip.tr(",", ".")) if formatted_text.include?("%")

      number = BigDecimal(value.to_s)
      number <= 1 ? number * 100 : number
    else
      text = value.to_s.strip
      has_percentage_sign = text.include?("%")
      number = BigDecimal(text.delete("%").strip.tr(",", "."))
      has_percentage_sign ? number : (number <= 1 ? number * 100 : number)
    end
  end

  def date_value(value)
    return if value.blank?
    return value.to_date if value.respond_to?(:to_date) && !value.is_a?(String)
    return Date.new(1899, 12, 30) + value.to_i if value.is_a?(Numeric)

    parse_text_date(value.to_s.strip)
  end

  def parse_text_date(value)
    [ "%d/%m/%Y", "%d-%m-%Y", "%Y-%m-%d" ].each do |format|
      return Date.strptime(value, format)
    rescue Date::Error
      next
    end

    raise ArgumentError, "#{value.inspect} no es una fecha válida"
  end

  def fingerprint_for(attributes)
    serialized = FINGERPRINT_FIELDS.map do |field|
      value = attributes[field]
      normalized_value = value.is_a?(BigDecimal) ? value.to_s("F") : value.to_s.strip
      "#{field}=#{normalized_value}"
    end

    Digest::SHA256.hexdigest(serialized.join("\u001F"))
  end
end
