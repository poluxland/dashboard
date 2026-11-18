class HaverQualityImporter
  class InvalidImport < StandardError; end

  FIELDS = EnvasadoraReport::HAVER_QUALITY_FIELDS.keys.freeze

  def initialize(payload)
    @payload = payload
  end

  def call(dry_run: false)
    validate_payload!
    summary = { days: 0, updated: 0, unchanged: 0, without_production: [], totals: FIELDS.index_with(0) }
    EnvasadoraReport.transaction do
      # Select and update the same latest reports even if a new shift is submitted concurrently.
      EnvasadoraReport.connection.execute("LOCK TABLE envasadora_reports IN SHARE ROW EXCLUSIVE MODE")
      @payload.fetch("rows").each do |source|
        date = Date.iso8601(source.fetch("date"))
        reports = EnvasadoraReport.where(date: date).order(:created_at, :id).index_by(&:turno).values
        raise InvalidImport, "No hay reportes de envasadora para #{date}." if reports.empty?

        reports.sort_by! { |report| EnvasadoraShiftSchedule.offsets(date, report.turno).first }
        productions = reports.map { |report| report.value_for_analytics("prodhaver") }
        if productions.any?(&:nil?)
          raise InvalidImport, "Hay producción desconocida para #{date}."
        end
        weights = productions.map(&:to_i)
        summary[:without_production] << date if weights.sum.zero?
        counts = FIELDS.to_h do |field|
          value = source[field]
          value = 0 if value.nil? && @payload["missing_policy"] == "zero"
          summary[:totals][field] += value || 0
          [ field, distribute(value, weights) ]
        end

        reports.each_with_index do |report, index|
          attributes = counts.transform_values { |values| values[index] }
          previous_import = report.source_data["haver_quality_import"]
          if previous_import && previous_import["sha256"] == @payload["sha256"] && previous_import["missing_policy"] == @payload["missing_policy"]
            unless attributes.all? { |field, value| report.public_send(field) == value }
              raise InvalidImport, "La calidad importada del #{date} cambió desde la carga anterior."
            end
            summary[:unchanged] += 1
            next
          end
          conflict = attributes.any? { |field, value| !report.public_send(field).nil? && report.public_send(field) != value }
          raise InvalidImport, "El reporte #{report.id} ya tiene cantidades de calidad diferentes." if conflict

          data = report.source_data.deep_dup
          data["haver_quality_import"] = {
            "filename" => @payload["filename"], "sheet" => @payload["sheet"], "sha256" => @payload["sha256"],
            "date" => source["date"], "column" => source["column"], "source" => source,
            "missing_policy" => @payload["missing_policy"], "allocation" => "proportional_production_largest_remainder",
            "production" => productions[index].to_s, "values" => attributes,
            "previous" => report.attributes.slice(*FIELDS), "at" => Time.current.iso8601
          }
          present = attributes.select { |_field, value| !value.nil? }.keys
          data["present_fields"] = (data.fetch("present_fields", []) - FIELDS + present).uniq
          data["invalid_fields"] = data.fetch("invalid_fields", []) - present
          report.update_columns(attributes.merge("source_data" => data, "updated_at" => Time.current)) unless dry_run
          summary[:updated] += 1
        end
        summary[:days] += 1
      end
    end
    summary
  end

  private

  def validate_payload!
    raise InvalidImport, "Falta la huella SHA256 del archivo." unless @payload["sha256"].to_s.match?(/\A[0-9a-f]{64}\z/)
    raise InvalidImport, "Selecciona cómo tratar las celdas vacías." unless %w[zero pending].include?(@payload["missing_policy"])
    rows = @payload.fetch("rows")
    raise InvalidImport, "No hay fechas para importar." if rows.empty?
    dates = rows.map { |row| Date.iso8601(row.fetch("date")) }
    raise InvalidImport, "Hay fechas duplicadas en la fuente." unless dates.uniq == dates
    rows.each do |row|
      FIELDS.each do |field|
        value = row[field]
        unless value.nil? || (value.is_a?(Integer) && value >= 0 && value <= 2_147_483_647)
          raise InvalidImport, "#{row['date']}: #{field} debe ser un entero no negativo."
        end
      end
    end
  end

  def distribute(quantity, weights)
    return Array.new(weights.size) if quantity.nil?
    return Array.new(weights.size, 0).tap { |values| values[-1] = quantity } if weights.sum.zero?

    total = weights.sum
    values = weights.map { |weight| quantity * weight / total }
    remaining = quantity - values.sum
    ranked = weights.each_index.sort_by { |index| [ -(quantity * weights[index] % total), index ] }
    ranked.first(remaining).each { |index| values[index] += 1 }
    values
  end
end
