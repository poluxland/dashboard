class EnvasadoraDashboard
  class InvalidFilter < StandardError; end

  SOURCES = {
    "haver" => { label: "Haver", production: %w[prodhaver], hours: %w[horas_haver] },
    "vento" => { label: "Vento", production: %w[prodvento], hours: %w[horas_vento] },
    "ambas" => { label: "Haver + Vento", production: %w[prodhaver prodvento], hours: %w[horas_haver horas_vento] }
  }.freeze
  SHIFTS = %w[TN TM TT].freeze
  DAYS = %w[Lun Mar Mié Jue Vie Sáb Dom].freeze
  PARETO_MODES = { "reason" => "Razón TPT", "production_state" => "Estado de producción", "impact" => "Impacto" }.freeze
  PERIODS = { "7" => "Últimos 7 días", "30" => "Últimos 30 días", "month" => "Mes actual", "previous" => "Mes anterior", "all" => "Todo" }.freeze

  attr_reader :from, :to, :period, :shifts, :weekdays, :source, :pareto_mode, :limit, :exclude_unscheduled, :include_missing_reason,
              :rows, :pareto, :charts, :production_title, :negative_count, :duplicate_report_count,
              :available_from, :available_to

  def initialize(params = {}, default_source:, only_producing: false)
    @only_producing = only_producing
    @params = params.to_h.stringify_keys
    @source = SOURCES.key?(@params["source"]) ? @params["source"] : default_source
    @source_config = SOURCES.fetch(@source)
    @pareto_mode = PARETO_MODES.key?(@params["pareto"]) ? @params["pareto"] : "reason"
    @limit = @params.fetch("top", 10).to_i.clamp(5, 25)
    @exclude_unscheduled = @params.fetch("exclude_unscheduled", "1") == "1"
    @include_missing_reason = @params["include_missing_reason"] == "1"
    @shifts = selected(@params["shifts"], SHIFTS)
    @weekdays = selected(@params["weekdays"], (1..7).map(&:to_s)).map(&:to_i)
    dates = [ EnvasadoraReport.minimum(:date), EnvasadoraReport.maximum(:date),
              TptEvent.minimum(:started_at)&.then { |time| operational_date(time) },
              TptEvent.maximum(:started_at)&.then { |time| operational_date(time) } ].compact
    @available_from, @available_to = dates.minmax
    last = @available_to || Time.current.in_time_zone("America/Santiago").to_date
    @from = parse_date(@params["from"], last - 29)
    @to = parse_date(@params["to"], last)
    @period = @params["period"] if PERIODS.key?(@params["period"])
    @period ||= "30" if @params["from"].blank? && @params["to"].blank?
    apply_period(@period, last)
    raise InvalidFilter, "La fecha Desde debe ser anterior o igual a Hasta." if @from > @to
    raise InvalidFilter, "Selecciona un período de hasta 10 años." if (@to - @from) > 3660
  end

  def call
    build_rows
    add_production
    @row_map.select! { |_key, row| row[:report].present? }
    @row_map.select! { |_key, row| row[:production]&.positive? } if @only_producing
    add_events
    finalize_rows
    build_pareto
    build_charts
    self
  end

  def production_label = @source_config[:label]
  def production_shift_count = @rows.count { |row| !row[:production].nil? }
  def production_total = production_shift_count.positive? ? @rows.sum { |row| row[:production].to_f } : nil
  def production_per_shift = divide(production_total, production_shift_count)
  def missing_hours_count = @rows.count { |row| row[:production].to_f.positive? && !row[:hours].to_f.positive? }
  def production_per_hour
    return unless missing_hours_count.zero?

    sacks_per_hour = divide(production_total, @rows.sum { |row| row[:hours].to_f })
    sacks_per_hour * 0.025 unless sacks_per_hour.nil?
  end
  def tpt_shift_count = @rows.count { |row| row[:observed_seconds].positive? }
  def downtime_per_shift = divide(@rows.sum { |row| row[:downtime_seconds] } / 60.0, tpt_shift_count)
  def downtime_percentage = divide(@rows.sum { |row| row[:downtime_seconds] } * 100, @rows.sum { |row| row[:observed_seconds] })
  def availability = divide(@operating_seconds * 100, @scheduled_seconds)
  def mtbf = divide(@operating_seconds / 3600.0, @failure_ids.size)
  def mttr = divide(@failure_seconds / 60.0, @failure_ids.size)
  def reliability = mtbf.nil? ? nil : mtbf.zero? ? 0.0 : Math.exp(-8.0 / mtbf) * 100
  def production_only_count = @rows.count { |row| !row[:production].nil? && row[:observed_seconds].zero? }
  def tpt_only_count = @rows.count { |row| row[:production].nil? && row[:observed_seconds].positive? }

  def machine_summaries
    @machine_summaries ||= EnvasadoraReportPresenter::PRODUCTION.map do |label, quantity_field, hours_field, factor, *_rest|
      values = @rows.map do |row|
        { production: row[:report].value_for_analytics(quantity_field), hours: row[:report].value_for_analytics(hours_field), planned: row[:planned_hours] }
      end
      quantities = values.filter_map { |value| value[:production] }
      timed = values.select { |value| !value[:hours].nil? }
      total = quantities.any? ? quantities.sum : nil
      hours = timed.sum { |value| value[:hours] }
      incomplete = values.count { |value| value[:production].nil? || value[:hours].nil? || (value[:production].positive? && !value[:hours].positive?) }
      {
        label: label, unit: label == "Bigbag" ? "unidades" : "sacos", total: total,
        tons_per_hour: incomplete.zero? ? divide(total && total * factor.to_d, hours) : nil,
        average_hours: divide(hours, timed.size),
        average_shift_hours: divide(timed.sum { |value| value[:planned] }, timed.size),
        reported_shifts: quantities.size, timed_shifts: timed.size, incomplete_shifts: incomplete
      }
    end
  end

  def stock_summaries
    @stock_summaries ||= begin
      inventories = @rows.filter_map do |row|
        report = row[:report]
        report.inventory unless report.inventory_for_display.nil?
      end
      EnvasadoraReport::CEMENTS.map do |cement|
        { product: cement, count: inventories.size,
          total: divide(inventories.sum { |inventory| inventory.fetch(cement)[:total] }, inventories.size),
          silo: divide(inventories.sum { |inventory| inventory.fetch(cement)[:silo] }, inventories.size),
          floor: divide(inventories.sum { |inventory| inventory.fetch(cement)[:floor] }, inventories.size) }
      end
    end
  end

  private

  def selected(input, allowed)
    values = Array(input).map(&:to_s) & allowed
    values.empty? ? allowed : values
  end

  def parse_date(value, fallback)
    return fallback if value.blank?
    raise InvalidFilter, "Usa fechas válidas en formato AAAA-MM-DD." unless value.to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/)
    Date.iso8601(value)
  rescue Date::Error
    raise InvalidFilter, "Usa fechas válidas en formato AAAA-MM-DD."
  end

  def apply_period(period, last)
    case period
    when "7", "30" then @from, @to = last - (period.to_i - 1), last
    when "month" then @from, @to = last.beginning_of_month, last
    when "previous" then @from, @to = last.prev_month.beginning_of_month, last.prev_month.end_of_month
    when "all" then @from, @to = @available_from || last, last
    end
  end

  def operational_date(time)
    date = time.utc.to_date
    [ date - 1, date, date + 1 ].each do |candidate|
      return candidate if SHIFTS.any? do |shift|
        start, finish = EnvasadoraShiftSchedule.window(candidate, shift)
        time >= start && time < finish
      end
    end
    date
  end

  def build_rows
    @row_map = {}
    (@from..@to).each do |date|
      next unless @weekdays.include?(date.cwday)
      @shifts.each do |shift|
        start, finish = EnvasadoraShiftSchedule.window(date, shift)
        planned_hours = EnvasadoraShiftSchedule.hours(date, shift)
        @row_map[[ date, shift ]] = {
          date: date, shift: shift, start: start, finish: finish,
          planned_hours: planned_hours, planned_finish: finish,
          production: nil, hours: nil, report: nil, observed: [], scheduled: [], stopped: [], selected_stops: [], failures: [],
          failure_ids: [], event_ids: [], causes: Hash.new(0.0)
        }
      end
    end
  end

  def add_production
    reports = EnvasadoraReport.where(date: @from..@to, turno: @shifts).order(:created_at, :id).to_a
    chosen = reports.index_by { |report| [ report.date, report.turno ] }
    @duplicate_report_count = 0
    reports.group_by { |report| [ report.date, report.turno ] }.each do |key, list|
      @duplicate_report_count += list.length - 1 if @row_map.key?(key)
    end
    chosen.each do |key, report|
      row = @row_map[key]
      next unless row
      production = @source_config[:production].map { |field| report.value_for_analytics(field) }
      hours = @source_config[:hours].map { |field| report.value_for_analytics(field) }
      row[:production] = production.none?(&:nil?) ? production.sum(&:to_f) : nil
      row[:hours] = hours.none?(&:nil?) ? hours.sum(&:to_f) : nil
      row[:report] = report
    end
  end

  def add_events
    @pareto_groups = Hash.new { |hash, key| hash[key] = { label: key, seconds: 0.0, ids: {} } }
    @failure_ids = {}
    @negative_count = 0
    windows = @row_map.values.sort_by { |row| row[:start] }
    return if windows.empty?
    lower = windows.first[:start]
    upper = windows.last[:finish]
    scope = TptEvent.all
    scope = scope.where("LOWER(BTRIM(reason)) <> ?", "missing reason") unless @include_missing_reason
    scope.where(started_at: lower...upper).where("duration_seconds < 0").pluck(:started_at).each do |time|
      index = windows.bsearch_index { |row| row[:finish] > time }
      @negative_count += 1 if index && windows[index][:start] <= time
    end
    events = scope.nonnegative.where("started_at < ? AND started_at + duration_seconds * INTERVAL '1 second' > ?", upper, lower).order(:started_at, :id)
    events.each do |event|
      start = event.started_at.utc
      finish = start + event.duration_seconds.to_r
      # Only windows intersecting this event can receive any of its duration.
      first_index = windows.bsearch_index { |row| row[:finish] > start }
      next unless first_index
      index = first_index
      while index < windows.length && windows[index][:start] < finish
        row = windows[index]
        clipped = [ [ start, row[:start] ].max, [ finish, row[:finish] ].min ]
        add_segment(row, event, clipped) if clipped.last > clipped.first
        index += 1
      end
    end
  end

  def add_segment(row, event, interval)
    seconds = (interval.last - interval.first).to_f
    row[:observed] << interval
    running = event.impact == "Correr"
    unscheduled = event.impact == "No programada"
    row[:scheduled] << interval unless unscheduled
    row[:stopped] << interval unless running || unscheduled
    if event.impact == "Parada no planificada" && interval.first < row[:planned_finish]
      row[:failures] << [ interval.first, [ interval.last, row[:planned_finish] ].min ]
      row[:failure_ids] << event.id
      @failure_ids[event.id] = true
    end
    return if running || (@exclude_unscheduled && unscheduled)
    row[:selected_stops] << interval
    row[:event_ids] << event.id
    row[:causes][event.reason] += seconds
    group = @pareto_groups[event.public_send(@pareto_mode)]
    group[:seconds] += seconds
    group[:ids][event.id] = true
  end

  def union_seconds(intervals)
    finish = nil
    intervals.sort_by(&:first).sum do |left, right|
      seconds = [ right - [ left, finish || left ].max, 0 ].max
      finish = [ right, finish || right ].max
      seconds.to_f
    end
  end

  def finalize_rows
    @scheduled_seconds = 0.0
    @operating_seconds = 0.0
    @failure_seconds = 0.0
    @rows = @row_map.values.filter_map do |row|
      next if row[:report].nil? && row[:observed].empty?
      row[:observed_seconds] = union_seconds(row[:observed])
      scheduled = union_seconds(within_program(row[:scheduled], row))
      stopped = union_seconds(within_program(row[:stopped], row))
      row[:available_seconds] = scheduled
      row[:operating_seconds] = [ scheduled - stopped, 0 ].max
      row[:failure_seconds] = union_seconds(row[:failures])
      row[:maintenance_seconds] = [ stopped - row[:failure_seconds], 0 ].max
      @scheduled_seconds += scheduled
      @operating_seconds += [ scheduled - stopped, 0 ].max
      @failure_seconds += union_seconds(row[:failures])
      # Pareto is additive event duration; the KPI percentage uses interval unions.
      row[:downtime_seconds] = union_seconds(row[:selected_stops])
      row[:event_count] = row[:event_ids].uniq.size
      row[:major_cause] = row[:causes].max_by { |_reason, seconds| seconds }
      row[:availability] = divide([ scheduled - stopped, 0 ].max * 100, scheduled)
      row[:coverage] = divide(union_seconds(within_program(row[:observed], row)) * 100, row[:planned_hours].hours)
      row.except(:observed, :scheduled, :stopped, :selected_stops, :failures, :event_ids, :failure_ids)
    end.sort_by { |row| [ row[:date], -SHIFTS.index(row[:shift]) ] }.reverse
  end

  def within_program(intervals, row)
    intervals.filter_map do |left, right|
      finish = [ right, row[:planned_finish] ].min
      [ left, finish ] if finish > left
    end
  end

  def build_pareto
    all = @pareto_groups.values.sort_by { |group| [ -group[:seconds], group[:label] ] }
    total = all.sum { |group| group[:seconds] }
    top = all.first(@limit)
    other = all.drop(@limit)
    if other.any?
      top << { label: "Otros (#{other.size})", seconds: other.sum { |group| group[:seconds] }, ids: other.reduce({}) { |memo, group| memo.merge(group[:ids]) } }
    end
    cumulative = 0.0
    @pareto = top.map do |group|
      cumulative += group[:seconds]
      { label: group[:label], minutes: group[:seconds] / 60, events: group[:ids].size,
        percentage: divide(group[:seconds] * 100, total), cumulative: divide(cumulative * 100, total) }
    end
  end

  def build_charts
    span = (@to - @from).to_i
    @production_title = "Producción por #{span <= 45 ? 'día' : span <= 250 ? 'semana' : 'mes'} y turno"
    buckets = Hash.new { |hash, key| hash[key] = {} }
    weekdays = Array.new(7) { SHIFTS.index_with { [] } }
    @rows.each do |row|
      next if row[:production].nil?
      date = row[:date]
      key = span <= 45 ? date : span <= 250 ? date.beginning_of_week : date.beginning_of_month
      buckets[key][row[:shift]] = buckets[key].fetch(row[:shift], 0) + row[:production]
      weekdays[date.cwday - 1][row[:shift]] << row[:production]
    end
    keys = buckets.keys.sort
    @charts = {
      production: { labels: keys.map { |key| key.strftime(span > 250 ? "%m/%Y" : "%d/%m/%Y") },
                    datasets: SHIFTS.map { |shift| { label: shift, data: keys.map { |key| buckets[key][shift] } } } },
      weekday: { labels: DAYS, datasets: SHIFTS.map { |shift| { label: shift, data: weekdays.map { |day| divide(day[shift].sum, day[shift].size) } } } },
      pareto: { labels: @pareto.pluck(:label), minutes: @pareto.pluck(:minutes), cumulative: @pareto.pluck(:cumulative) }
    }
  end

  def divide(numerator, denominator)
    numerator.to_f / denominator if !numerator.nil? && denominator.positive?
  end
end
