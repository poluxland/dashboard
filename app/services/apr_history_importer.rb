require "roo"
require "digest"

class AprHistoryImporter
  class InvalidSpreadsheet < StandardError; end

  SOURCE_FILE = "Seguridad PTM.xlsx"
  SHEET_NAME = "INFORME SEGURIDAD"
  COLUMNS = %w[Fecha Área Actividad Comentarios].freeze
  DAY_STATUSES = [ "Descanso compensatorio", "Feriado legal", "Vacaciones" ].freeze
  DATE_FORMAT = /\A\d{1,2}\/\d{1,2}\/\d{4}\z/

  def initialize(path)
    @path = path
  end

  def call(apply: false)
    entries = read_entries
    scope = AprHistoryEntry.where(source_file: SOURCE_FILE, source_sheet: entries.first.fetch(:source_sheet))
    AprHistoryEntry.transaction do
      existing = verify_existing(scope, entries)
      new_rows = entries.reject { |entry| existing.key?(entry.fetch(:source_row)) }
      inserted = 0
      if apply && new_rows.any?
        inserted = AprHistoryEntry.insert_all(new_rows, unique_by: :index_apr_history_entries_on_source).rows.size
        verify_existing(scope, entries)
      end

      {
        records: entries.size,
        source_rows: entries.sum { |entry| entry.fetch(:source_end_row) - entry.fetch(:source_row) + 1 },
        activities: entries.sum { |entry| entry.fetch(:activities).size },
        comments: entries.count { |entry| entry[:observations].present? },
        date_ranges: entries.count { |entry| entry[:date] != entry[:end_date] },
        non_workdays: entries.count { |entry| entry[:day_status].present? },
        plants: entries.group_by { |entry| entry.fetch(:plant) }.transform_values(&:size),
        from: entries.map { |entry| entry.fetch(:date) }.min,
        to: entries.map { |entry| entry.fetch(:end_date) }.max,
        already_present: existing.size,
        inserted: inserted
      }
    end
  end

  private

  def read_entries
    workbook = Roo::Excelx.new(@path)
    sheet_name = workbook.sheets.find { |name| name.squish == SHEET_NAME }
    raise InvalidSpreadsheet, "Falta la hoja #{SHEET_NAME}." unless sheet_name

    sheet = workbook.sheet(sheet_name)
    unless sheet.row(2).first(4).map { |value| value.to_s.strip } == COLUMNS
      raise InvalidSpreadsheet, "Los encabezados de la fila 2 deben ser Fecha, Área, Actividad y Comentarios."
    end

    entries = []
    (3..sheet.last_row).each do |number|
      values = sheet.row(number)
      date, area, activity, comments = values
      next if values.all?(&:blank?)

      if values.drop(4).any?(&:present?)
        raise InvalidSpreadsheet, "La fila #{number} contiene datos fuera de las columnas esperadas."
      end

      if date.present?
        start_date, end_date = parse_dates(date, number)
        entries << {
          date: start_date, end_date: end_date, source_file: SOURCE_FILE, source_sheet: sheet_name,
          source_row: number, source_end_row: number, source_date: date.to_s,
          source_area: area.to_s.presence, source_activity: activity.to_s.presence, observations: comments.to_s.presence
        }
      else
        append_continuation(entries.last, number, area, activity, comments)
      end
    end
    raise InvalidSpreadsheet, "El Excel no contiene registros históricos." if entries.empty?

    entries.map { |entry| prepare_entry(entry) }
  ensure
    workbook&.close
  end

  def parse_dates(value, number)
    if value.is_a?(Date) || value.is_a?(Time)
      return [ value.to_date, value.to_date ]
    end

    parts = value.to_s.strip.split(/\s+al\s+/i, -1)
    if parts.size.in?(1..2) && parts.all? { |part| DATE_FORMAT.match?(part) }
      start_date, finish = parts.map { |part| Date.strptime(part, "%d/%m/%Y") }
      end_date = finish || start_date
      return [ start_date, end_date ] if end_date >= start_date
    end
    raise InvalidSpreadsheet, "La fila #{number} contiene una fecha o un período inválido."
  rescue Date::Error
    raise InvalidSpreadsheet, "La fila #{number} contiene una fecha o un período inválido."
  end

  def append_continuation(entry, number, area, activity, comments)
    unless entry && number == entry[:source_end_row] + 1 && area.blank?
      raise InvalidSpreadsheet, "La fila #{number} tiene datos sin una fecha que los identifique."
    end

    entry[:source_end_row] = number
    entry[:source_activity] = [ entry[:source_activity], activity.to_s.presence ].compact.join("\n").presence
    entry[:observations] = [ entry[:observations], comments.to_s.presence ].compact.join("\n").presence
  end

  def prepare_entry(entry)
    area = entry[:source_area].to_s.squish
    text = entry[:source_activity].to_s
    status = DAY_STATUSES.find { |candidate| candidate.casecmp?(area) || candidate.casecmp?(text.squish) }
    activities = text.split("•").map(&:strip).reject(&:blank?)
    activities.reject! { |activity| status.casecmp?(activity.squish) } if status
    entry.merge(
      plant: area.casecmp?("Planta Calbuco") ? "CALBUCO" : "PTM",
      day_status: status, activities: activities, source_fingerprint: Digest::SHA256.hexdigest(entry.to_json)
    )
  end

  def verify_existing(scope, entries)
    existing = scope.pluck(:source_row, :source_fingerprint).to_h
    entries.each do |entry|
      number = entry.fetch(:source_row)
      if existing.key?(number) && existing[number] != entry[:source_fingerprint]
        raise InvalidSpreadsheet, "La fila #{number} ya existe con otros datos. Revisa la versión del archivo."
      end
    end
    existing
  end
end
