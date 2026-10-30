require "digest"
require "bigdecimal"
require "set"

class EnvasadoraHistoryImporter
  class InvalidHistory < StandardError; end
  COLUMNS = JSON.parse(Rails.root.join("config/envasadora_history_columns.json").read).freeze
  HOURS = %w[horas_haver horas_vento horas_bigbag].freeze
  TEST_RECORD_FIELDS = %w[id date turno created_at updated_at sent_at prodhaver horas_haver].freeze

  def initialize(payload)
    @payload = payload
  end

  def prepare
    expected = COLUMNS.to_h { |column| [ column["column"], column["header"] ] }
    raise InvalidHistory, "Las columnas no corresponden al histórico esperado." unless @payload["headers"] == expected
    raise InvalidHistory, "Falta la huella SHA256 del archivo." unless @payload["sha256"].to_s.match?(/\A[0-9a-f]{64}\z/)
    raise InvalidHistory, "La regla de selección debe ser la primera fila." unless @payload["selection"] == "first"

    @prepared = []
    @duplicates = 0
    @skipped = @payload.fetch("skipped_without_shift", 0).to_i
    chosen = {}
    @payload.fetch("rows").sort_by { |row| row.fetch("row") }.each do |source|
      cells = source.fetch("cells")
      next @skipped += 1 unless EnvasadoraReport::SHIFTS.key?(cells["B"])
      date = Date.iso8601(cells.fetch("A"))
      key = [ date, cells["B"] ]
      if chosen[key]
        @duplicates += 1
        next
      end
      chosen[key] = true
      @prepared << prepare_record(source, date)
    end
    raise InvalidHistory, "No hay registros con fecha y turno válidos." if @prepared.empty?
    summary
  rescue KeyError, Date::Error, TypeError, ArgumentError => error
    raise InvalidHistory, "No se pudo preparar el histórico: #{error.message}"
  end

  def call(replace_test_record: nil)
    prepare unless @prepared
    EnvasadoraReport.transaction do
      EnvasadoraReport.connection.execute("LOCK TABLE envasadora_reports IN SHARE ROW EXCLUSIVE MODE")
      fingerprints = @prepared.pluck(:source_fingerprint)
      known = EnvasadoraReport.where(source_fingerprint: fingerprints).pluck(:source_fingerprint).to_set
      pending = @prepared.reject { |row| known.include?(row[:source_fingerprint]) }
      if replace_test_record
        test = EnvasadoraReport.find_by(id: replace_test_record.fetch("id"))
        if test
          actual = test.attributes.slice(*TEST_RECORD_FIELDS).as_json
          expected = replace_test_record.slice(*TEST_RECORD_FIELDS)
          unless EnvasadoraReport.count == 1 && !test.historical? && actual == expected
            raise InvalidHistory, "El registro de prueba cambió o hay otros reportes. No se eliminó ningún registro."
          end
          test.destroy!
        elsif pending.any?
          raise InvalidHistory, "El registro de prueba ya no existe. No se realizó la carga."
        end
      end
      # Historical source values may violate today's form rules. Preserve them
      # as read-only snapshots and keep their issues, never silently correct them.
      pending.each_slice(150) { |batch| EnvasadoraReport.insert_all!(batch) }
      summary.merge(created: pending.length, already_present: known.size, test_record_removed: test.present?)
    end
  end

  private

  def prepare_record(source, date)
    cells = source.fetch("cells")
    attributes = { date: date, turno: cells["B"], author_email: "Histórico Excel" }
    present_fields = []
    invalid_fields = []
    issues = []
    COLUMNS.each do |column|
      field = column["field"]
      next unless field
      raw = cells[column["column"]]
      next if raw.nil? || raw == ""
      present_fields << field
      if EnvasadoraReport.type_for_attribute(field).type == :decimal
        number = BigDecimal(raw.to_s)
        raise InvalidHistory, "Fila #{source['row']}: #{column['header']} no es finito." unless number.finite?
        attributes[field] = number
        if number.negative? || HOURS.include?(field) && number > 8
          invalid_fields << field
          issues << "#{column['header']}: valor #{raw} fuera del rango esperado; se conserva el original."
        end
      else
        attributes[field] = raw
      end
    end
    EnvasadoraReport::SILOS.each do |_id, silo|
      silo[:readings].each do |field|
        value = attributes[field]
        next unless value && (value < 0 || value > silo[:height])
        invalid_fields << field
        issues << "#{field}: medida #{value.to_s('F')} fuera de 0–#{silo[:height]}; se conserva el original."
      end
    end
    missing_hours = HOURS - present_fields
    issues << "Horas no informadas en el archivo: #{missing_hours.join(', ')}." if missing_hours.any?
    record = EnvasadoraReport.new(attributes)
    unless record.valid?
      issues.concat(record.errors.full_messages)
      invalid_fields.concat(record.errors.attribute_names.map(&:to_s))
    end
    source_data = {
      "sha256" => @payload["sha256"], "sheet" => @payload["sheet"],
      "cells" => COLUMNS.to_h { |column| [ column["header"], cells[column["column"]] ] },
      "present_fields" => present_fields, "invalid_fields" => invalid_fields.uniq,
      "issues" => issues.uniq
    }
    now = Time.current
    record.attributes.except("id").symbolize_keys.merge(
      source_filename: @payload.fetch("filename"), source_row: source.fetch("row"), source_data: source_data,
      source_fingerprint: Digest::SHA256.hexdigest("#{@payload['sha256']}:#{@payload['sheet']}:#{source['row']}"),
      created_at: now, updated_at: now
    )
  end

  def summary
    {
      selected: @prepared.length, skipped_without_shift: @skipped, older_duplicates: @duplicates,
      from: @prepared.map { |row| row[:date] }.min, to: @prepared.map { |row| row[:date] }.max,
      records_with_issues: @prepared.count { |row| row[:source_data]["issues"].any? },
      production_haver: @prepared.sum { |row| row[:prodhaver] || 0 }
    }
  end
end
