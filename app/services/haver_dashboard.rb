class HaverDashboard
  class InvalidFilter < StandardError; end

  DEFAULT_IDEAL = 50.0
  ESTIMATED_FAILURE_RATE = 0.15

  attr_reader :ideal, :days, :shifts, :totals, :dashboard

  def initialize(params = {})
    values = params.to_h.stringify_keys
    @ideal = DEFAULT_IDEAL
    if values["ideal"].present?
      @ideal = Float(values["ideal"].to_s.tr(",", "."))
      raise InvalidFilter, "El rendimiento ideal debe ser mayor que cero." unless @ideal.finite? && @ideal.positive?
    end
    period = EnvasadoraDashboard::PERIODS.key?(values["period"]) ? values["period"] : "previous"
    @dashboard = EnvasadoraDashboard.new({ period: period }, default_source: "haver", only_producing: true).call
    producing_rows = @dashboard.rows
    # Keep recorded losses on days with no good production in the bag totals.
    reports = EnvasadoraReport.where(date: @dashboard.from..@dashboard.to).order(:created_at, :id).index_by { |report| [ report.date, report.turno ] }.values
    losses_without_production = reports.filter_map do |report|
      production = report.value_for_analytics("prodhaver")
      next if production&.positive?
      next unless EnvasadoraReport::HAVER_QUALITY_FIELDS.keys.any? { |field| report.value_for_analytics(field).to_i.positive? }

      { date: report.date, shift: report.turno, production: production, report: report }
    end
    rows = producing_rows + losses_without_production
    rows_by_date = rows.group_by { |row| row[:date] }
    @days = rows_by_date.keys.sort.map do |date|
      summarize(rows_by_date.fetch(date)).merge(date: date)
    end
    @shifts = rows.sort_by { |row| [ row[:date], EnvasadoraShiftSchedule.offsets(row[:date], row[:shift]).first ] }.reverse.map do |row|
      summarize([ row ]).merge(date: row[:date], shift: row[:shift],
        comment: row[:report].value_for_analytics("comentarios_haver"))
    end
    @totals = summarize(rows)
  rescue ArgumentError
    raise InvalidFilter, "Revisa el rendimiento ideal."
  end

  private

  def ratio(numerator, denominator)
    numerator / denominator.to_f if numerator && denominator && denominator.positive?
  end

  def summarize(rows)
    bags = summarize_bags(rows)
    rows = rows.select { |row| row[:production]&.positive? }
    productions = rows.map { |row| row[:production] }
    hours = rows.map { |row| row[:hours] }
    tons = productions.any? && productions.none?(&:nil?) ? productions.sum * 0.025 : nil
    valid_hours = hours.any? && hours.none?(&:nil?) && rows.none? { |row| row[:production].to_f.positive? && !row[:hours].to_f.positive? }
    rate = ratio(tons, valid_hours ? hours.sum : nil)
    performance = ratio(rate, @ideal)&.*(100)
    quality = bags[:quality]
    available = rows.sum { |row| row[:planned_hours] } * 3600
    maintenance = rows.sum { |row| row[:maintenance_seconds] }
    failures = rows.sum { |row| row[:failure_seconds] }
    missing_vorne = rows.select { |row| row[:available_seconds].zero? }
    estimated_rows = missing_vorne.select { |row| row[:hours]&.positive? }
    estimated_operation = estimated_rows.sum { |row| row[:hours] } * 3600
    estimated_failures = estimated_operation * ESTIMATED_FAILURE_RATE
    reliability_operation = valid_hours ? hours.sum * 3600 : nil
    reliability_failures = failures + estimated_failures
    complete_reliability = valid_hours && missing_vorne.size == estimated_rows.size
    reliability = ratio(reliability_operation, complete_reliability ? reliability_operation + reliability_failures : nil)&.*(100)
    # Internally, absent Vorne uses zero maintenance and failures of 15% of declared operation.
    complete_availability = rows.any? && missing_vorne.size == estimated_rows.size
    availability = ratio(available - maintenance - reliability_failures, complete_availability ? available : nil)&.*(100)
    oee = availability && performance && quality ? availability * performance * quality / 10_000 : nil
    bags.merge(tons: tons, rate: rate, performance: performance,
      availability: availability, reliability: reliability, oee: oee,
      estimated_reliability_count: estimated_rows.size, estimated_failure_hours: estimated_failures / 3600,
      available_hours: available / 3600, maintenance_hours: maintenance / 3600, failure_hours: failures / 3600,
      reports: rows.size, missing_vorne: rows.count { |row| row[:planned_hours].positive? && row[:available_seconds].zero? })
  end

  def summarize_bags(rows)
    quantities = {
      good_bags: rows.map { |row| row[:production] },
      broken_bags: rows.map { |row| row[:report].value_for_analytics("sacos_rotos_haver") },
      unrecognized_bags: rows.map { |row| row[:report].value_for_analytics("sacos_no_reconocidos_haver") },
      discarded_bags: rows.map { |row| row[:report].value_for_analytics("sacos_descartados_haver") }
    }
    counts = quantities.transform_values { |values| values.sum if values.any? && values.none?(&:nil?) }
    total = counts[:broken_bags] + counts[:discarded_bags] if counts[:broken_bags] && counts[:discarded_bags]
    loss_rate = ratio(total, counts[:good_bags])&.*(100)
    counts.merge(total_haver: total, quality: loss_rate && 100 - loss_rate,
      broken: ratio(counts[:broken_bags], counts[:good_bags])&.*(100),
      missing_broken: quantities[:broken_bags].count(nil),
      missing_quality: rows.count { |row| %w[sacos_rotos_haver sacos_descartados_haver].any? { |field| row[:report].value_for_analytics(field).nil? } })
  end
end
