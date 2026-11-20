class HaverDailyReport
  CHILE = Time.find_zone!("America/Santiago")
  HOUR = 5
  TREND_DAYS = 7
  SHIFT_METRICS = [
    [ "Producción", :tons, " t", 1 ],
    [ "Rendimiento real", :rate, " t/h", 1 ],
    [ "OEE", :oee, "%", 1 ],
    [ "Calidad", :quality, "%", 2 ],
    [ "Sacos buenos", :good_bags, "", 0 ],
    [ "Sacos no reconocidos", :unrecognized_bags, "", 0 ],
    [ "Sacos rotos", :broken_bags, "", 0 ],
    [ "Sacos descartados", :discarded_bags, "", 0 ]
  ].freeze
  TOTAL_METRICS = SHIFT_METRICS.first(2).concat([
    [ "Rendimiento sobre ideal", :performance, "%", 1 ],
    [ "Disponibilidad", :availability, "%", 1 ],
    [ "Confiabilidad", :reliability, "%", 1 ],
    *SHIFT_METRICS.drop(2)
  ]).freeze
  BAG_FIELDS = {
    good_bags: "prodhaver",
    unrecognized_bags: "sacos_no_reconocidos_haver",
    broken_bags: "sacos_rotos_haver",
    discarded_bags: "sacos_descartados_haver"
  }.freeze

  attr_reader :cutoff, :shifts, :periods, :ideal, :production_by_day

  def self.cutoff_for(date)
    CHILE.local(date.year, date.month, date.day, HOUR)
  end

  def production_data?
    production_by_day.any? { |day| day[:tons] || day[:rate] }
  end

  def initialize(scheduled_at:)
    @cutoff = scheduled_at.in_time_zone(CHILE)
    last_date = cutoff.to_date.yesterday
    recent_dates = (last_date - 6)..last_date
    recent_reports = reports_for(recent_dates).index_by { |report| [ report.date, report.turno ] }
    candidates = recent_dates.flat_map do |date|
      EnvasadoraReport::SHIFTS.keys.filter_map do |shift|
        [ date, shift ] if EnvasadoraShiftSchedule::WEEK.fetch(date.cwday).key?(shift) || recent_reports.key?([ date, shift ])
      end
    end
    slots = candidates.last(3)
    last_report_date = slots.last.first
    week = last_report_date.beginning_of_week(:monday)..last_report_date
    month = last_report_date.beginning_of_month..last_report_date
    trend = (last_report_date - (TREND_DAYS - 1))..last_report_date
    start = [ slots.first.first, week.begin, month.begin, trend.begin ].min
    dashboard = HaverDashboard.new(from: start.iso8601, to: last_report_date.iso8601, reported_before: cutoff)
    @ideal = dashboard.ideal
    by_shift = dashboard.shifts.index_by { |row| [ row[:date], row[:shift] ] }
    by_day = dashboard.days.index_by { |row| row[:date] }
    @production_by_day = trend.map do |date|
      day = by_day.fetch(date, {})
      { date: date, tons: day[:tons], rate: day[:rate] }
    end

    @shifts = slots.map do |date, shift|
      recorded = recent_reports[[ date, shift ]]
      metrics = by_shift[[ date, shift ]] || idle_metrics(recorded)
      metrics.merge(date: date, shift: shift, status: shift_status(date, shift, recorded),
                    received: recorded.present?, comment: recorded&.value_for_analytics("comentarios_haver"))
    end
    @periods = [
      { label: "Tres turnos", range: slots.first.first..last_report_date,
        totals: dashboard.totals_for { |row| slots.include?([ row[:date], row[:shift] ]) } },
      { label: "Semana", range: week, totals: dashboard.totals_for { |row| week.cover?(row[:date]) } },
      { label: "Mes", range: month, totals: dashboard.totals_for { |row| month.cover?(row[:date]) } }
    ]
  end

  private

  def reports_for(dates)
    EnvasadoraReport.where(date: dates, created_at: ..cutoff).order(:created_at, :id)
  end

  def idle_metrics(recorded)
    return {} unless recorded

    quantities = BAG_FIELDS.transform_values { |field| recorded.value_for_analytics(field) }
    quantities.merge(tons: 0.0) if quantities[:good_bags] == 0
    quantities
  end

  def shift_status(date, shift, report)
    if report
      production = report.value_for_analytics("prodhaver")
      return "Producción sin informar" if production.nil?
      return "Sin producción Haver" if production.zero?
      return "Informado"
    end

    _, end_hour = EnvasadoraShiftSchedule.offsets(date, shift)
    end_day = date + end_hour.div(24)
    ends_at = CHILE.local(end_day.year, end_day.month, end_day.day, end_hour % 24)
    cutoff < ends_at ? "En curso al corte · cierra #{ends_at.strftime('%H:%M')}" : "Pendiente al corte"
  end
end
