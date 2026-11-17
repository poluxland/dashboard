class HaverDashboard
  class InvalidFilter < StandardError; end

  DEFAULT_IDEAL = 50.0

  attr_reader :ideal, :days, :shifts, :totals, :dashboard

  def initialize(params = {})
    values = params.to_h.stringify_keys
    @ideal = DEFAULT_IDEAL
    if values["ideal"].present?
      @ideal = Float(values["ideal"].to_s.tr(",", "."))
      raise InvalidFilter, "El rendimiento ideal debe ser mayor que cero." unless @ideal.finite? && @ideal.positive?
    end
    period = EnvasadoraDashboard::PERIODS.key?(values["period"]) ? values["period"] : "7"
    @dashboard = EnvasadoraDashboard.new({ period: period }, default_source: "haver").call
    producing_rows = @dashboard.rows.select { |row| row[:production]&.positive? }
    rows_by_date = producing_rows.group_by { |row| row[:date] }
    @days = (@dashboard.from..@dashboard.to).map do |date|
      summarize(rows_by_date.fetch(date, [])).merge(date: date)
    end
    @shifts = producing_rows.map do |row|
      summarize([ row ]).merge(date: row[:date], shift: row[:shift],
        comment: row[:report].value_for_analytics("comentarios_haver"))
    end
    @totals = summarize(producing_rows)
  rescue ArgumentError
    raise InvalidFilter, "Revisa el rendimiento ideal."
  end

  private

  def ratio(numerator, denominator)
    numerator / denominator.to_f if numerator && denominator && denominator.positive?
  end

  def summarize(rows)
    productions = rows.map { |row| row[:production] }
    hours = rows.map { |row| row[:hours] }
    broken = rows.map { |row| row[:report].value_for_analytics("sacos_rotos_haver") }
    tons = productions.any? && productions.none?(&:nil?) ? productions.sum * 0.025 : nil
    valid_hours = hours.any? && hours.none?(&:nil?) && rows.none? { |row| row[:production].to_f.positive? && !row[:hours].to_f.positive? }
    rate = ratio(tons, valid_hours ? hours.sum : nil)
    performance = ratio(rate, @ideal)&.*(100)
    broken_rate = ratio(broken.any? && broken.none?(&:nil?) ? broken.sum : nil, productions.none?(&:nil?) ? productions.sum : nil)&.*(100)
    quality = broken_rate && 100 - broken_rate
    available = rows.sum { |row| row[:available_seconds] }
    maintenance = rows.sum { |row| row[:maintenance_seconds] }
    failures = rows.sum { |row| row[:failure_seconds] }
    operating = rows.sum { |row| row[:operating_seconds] }
    complete_vorne = rows.any? && rows.all? { |row| row[:available_seconds].positive? || row[:planned_hours].zero? }
    availability = ratio(available - maintenance - failures, complete_vorne ? available : nil)&.*(100)
    reliability = ratio(operating, complete_vorne ? operating + failures : nil)&.*(100)
    oee = availability && performance && quality ? availability * performance * quality / 10_000 : nil
    { tons: tons, rate: rate, performance: performance, broken: broken_rate, quality: quality,
      availability: availability, reliability: reliability, oee: oee,
      available_hours: available / 3600, maintenance_hours: maintenance / 3600, failure_hours: failures / 3600,
      reports: rows.size, missing_broken: broken.count(nil), missing_vorne: rows.count { |row| row[:planned_hours].positive? && row[:available_seconds].zero? } }
  end
end
