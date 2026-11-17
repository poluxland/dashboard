class PtmDashboard
  PERIODS = { "previous" => "Mes anterior", "7" => "Últimos 7 días", "30" => "Últimos 30 días", "month" => "Mes actual", "all" => "Todo" }.freeze
  attr_reader :period, :from, :to, :reports

  def initialize(period = nil)
    @period = PERIODS.key?(period) ? period : "previous"
    latest = PtmReport.where("date <= ?", Date.current).maximum(:date) || Date.current
    @from, @to = case @period
    when "7", "30" then [ latest - (@period.to_i - 1), latest ]
    when "month" then [ latest.beginning_of_month, latest.end_of_month ]
    when "all" then [ PtmReport.minimum(:date) || latest, latest ]
    else [ latest.prev_month.beginning_of_month, latest.prev_month.end_of_month ]
    end
    @reports = PtmReport.includes(:ptm_events).where(date: @from..@to).order(date: :desc, shift: :asc).to_a
  end

  def totals(rows = reports)
    known = rows.select { |report| report.production.present? }
    timed = rows.select(&:usable_times?)
    tons = known.sum(&:production) * 0.025
    { tons: known.any? ? tons : nil, sacks: known.sum(&:production), rate: known.any? ? tons / (known.size * 8) : nil,
      minutes: rows.sum(&:stopped_minutes), events: rows.sum { |r| r.ptm_events.size },
      available: timed.any? ? (1 - timed.sum(&:stopped_minutes) / (timed.size * 480.0)) * 100 : nil,
      coverage: timed.size, missing_production: rows.size - known.size }
  end

  def pareto(attribute)
    values = reports.flat_map(&:ptm_events).group_by { |event| event.public_send(attribute).presence || "Sin informar" }
      .map { |label, events| { label: label, minutes: events.sum { |event| event.minutes.to_f }, events: events.size } }
      .sort_by { |row| -row[:minutes] }
    total = values.sum { |row| row[:minutes] }
    cumulative = 0
    values.each do |row|
      cumulative += row[:minutes]
      row[:cumulative] = total.positive? ? cumulative / total * 100 : 0
    end
    values
  end

  def review_reports
    @review_reports ||= PtmReport.where.not(review_notes: [ nil, "" ]).order(:date, :shift).to_a
  end

  def charts
    days = reports.group_by(&:date).sort.map { |date, rows| totals(rows).merge(date: date.iso8601) }
    shifts = PtmReport::SHIFTS.keys.map { |shift| totals(reports.select { |r| r.shift == shift }).merge(shift: shift) }
    { days: days, shifts: shifts, equipment: pareto(:equipment), causes: pareto(:reason) }
  end
end
