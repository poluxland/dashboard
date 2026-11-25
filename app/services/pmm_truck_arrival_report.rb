class PmmTruckArrivalReport
  class InvalidFilter < ArgumentError; end

  RANGES = { "last" => "Último día", "7" => "7 días", "30" => "30 días", "month" => "Mes", "all" => "Todo" }.freeze
  TIME_RANGES = { "Todo el día" => [ 0, 1440 ], "05:00 a 12:00" => [ 300, 720 ],
                  "12:00 a 18:00" => [ 720, 1080 ], "18:00 a 24:00" => [ 1080, 1440 ] }.freeze
  GROUPS = { "auto" => "Automático", "day" => "Día", "week" => "Semana", "month" => "Mes" }.freeze
  BANDS = { 30 => "30 min", 60 => "1 hora", 120 => "2 horas" }.freeze
  HOUR_BUCKETS = {
    30 => Arel.sql("FLOOR(EXTRACT(EPOCH FROM llegada) / 1800)::integer * 30"),
    60 => Arel.sql("FLOOR(EXTRACT(EPOCH FROM llegada) / 3600)::integer * 60"),
    120 => Arel.sql("FLOOR(EXTRACT(EPOCH FROM llegada) / 7200)::integer * 120")
  }.freeze
  DIMENSIONS = {
    material_ids: { label: "Materia prima", title: "Por materia prima", column: PmmTruck.arel_table[:pmm_material_id] },
    types: { label: "Tipo de equipo", title: "Por tipo de equipo", column: Arel.sql("COALESCE(NULLIF(BTRIM(pmm_trucks.tipo), ''), 'Sin registro')") },
    statuses: { label: "Estado del registro", title: "Por estado del registro", column: Arel.sql("COALESCE(NULLIF(BTRIM(pmm_trucks.cause), ''), 'Sin registro')") }
  }.freeze
  DATE_BUCKETS = {
    "day" => :fecha, "week" => Arel.sql("DATE_TRUNC('week', pmm_trucks.fecha)::date"),
    "month" => Arel.sql("DATE_TRUNC('month', pmm_trucks.fecha)::date")
  }.freeze
  WITH_COMMENT = "NULLIF(BTRIM(pmm_trucks.motive), '') IS NOT NULL OR NULLIF(BTRIM(pmm_trucks.other), '') IS NOT NULL".freeze
  ROW_METRICS = [ Arel.sql("COUNT(*)"), Arel.sql("AVG(pmm_trucks.wait)") ].freeze
  TOTAL_METRICS = [ *ROW_METRICS,
    Arel.sql("PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY pmm_trucks.wait)"),
    Arel.sql("PERCENTILE_DISC(0.9) WITHIN GROUP (ORDER BY pmm_trucks.wait)"),
    Arel.sql("MAX(pmm_trucks.wait)"), Arel.sql("COUNT(*) FILTER (WHERE #{WITH_COMMENT})")
  ].freeze

  attr_reader :from, :to, :first_date, :last_date, :time_from, :time_to, :band, :group, :options

  def initialize(filters, today:)
    @base = PmmTruck.measured.where(wait: 0..).where.not(fecha: nil).where("llegada < TIME '24:00'")
    @first_date, @last_date = @base.pick(Arel.sql("MIN(fecha)"), Arel.sql("MAX(fecha)"))
    @first_date ||= today
    @last_date ||= today
    @range = filters[:range].presence_in(RANGES.keys) || "30"
    default = preset(@range)
    @from = filters[:from].present? ? Date.iso8601(filters[:from]) : default.begin
    @to = filters[:to].present? ? Date.iso8601(filters[:to]) : default.end
    @time_from = Integer(filters[:time_from].presence || "0", 10)
    @time_to = Integer(filters[:time_to].presence || "1440", 10)
    raise InvalidFilter unless @from <= @to && @time_from >= 0 && @time_from < @time_to && @time_to <= 1440

    @band = Integer(filters[:band].to_s, 10, exception: false).presence_in(BANDS.keys) || 60
    @group = filters[:group].presence_in(GROUPS.keys) || "auto"
    @options = {
      material_ids: PmmMaterial.order(:nombre, :id).pluck(:nombre, :id).map { |name, id| [ name.presence || "Sin nombre", id.to_s ] },
      types: dimension_values(:types),
      statuses: dimension_values(:statuses)
    }
    @selected = @options.to_h { |key, choices| [ key, Array(filters[key]) & choices.map(&:last) ] }
    @observation_mode = filters[:observations] == "special" ? "special" : "comments"
    @query = filters[:q].to_s.strip.first(120)
    @sort = filters[:sort] == "recent" ? "recent" : "wait"
  rescue Date::Error, ArgumentError, TypeError
    raise InvalidFilter
  end

  def preset(name)
    first = case name
    when "last" then last_date
    when "7" then last_date - 6
    when "30" then last_date - 29
    when "month" then last_date.beginning_of_month
    when "all" then first_date
    else return
    end
    [ first, first_date ].max..last_date
  end

  def query(**changes)
    { from: from, to: to, range: active_preset, time_from: time_from, time_to: time_to, band: band, group: group,
      **@selected, observations: @observation_mode, q: @query.presence, sort: @sort }.merge(changes).compact
  end

  def active_preset
    [ @range, *RANGES.keys ].find { |key| preset(key) == (from..to) }
  end

  def selected?(key, value)
    @selected.fetch(key).include?(value)
  end

  def toggle(key, value)
    selected = @selected.fetch(key)
    query(key => selected?(key, value) ? selected - [ value ] : selected + [ value ])
  end

  def totals
    @totals ||= %i[count average median p90 maximum comments].zip(scope.pick(*TOTAL_METRICS)).to_h
  end

  def charts
    return [] if totals[:count].zero?

    [ hourly_chart, date_chart ]
  end

  def rankings
    DIMENSIONS.to_h do |key, dimension|
      data = breakdown(scope(except: key), dimension.fetch(:column)).transform_keys(&:to_s)
      rows = options.fetch(key).filter_map do |label, value|
        next unless data.key?(value) || selected?(key, value)

        count, average = data.fetch(value, [ 0, nil ])
        { label: label, value: value, count: count, average: average }
      end
      [ key, { title: dimension.fetch(:title), label: dimension.fetch(:label), rows: rows.sort_by { |row| [ -row[:count], row[:label] ] } } ]
    end
  end

  def observations
    records = scope
    records = if @observation_mode == "special"
      records.where("(#{WITH_COMMENT}) OR NULLIF(BTRIM(pmm_trucks.cause), '') <> ?", "Normal")
    else
      records.where(WITH_COMMENT)
    end
    if @query.present?
      pattern = "%#{PmmTruck.sanitize_sql_like(@query)}%"
      records = records.joins(:pmm_material).where(
        "pmm_trucks.motive ILIKE :q OR pmm_trucks.other ILIKE :q OR pmm_trucks.patente ILIKE :q OR " \
        "pmm_trucks.cause ILIKE :q OR pmm_materials.nombre ILIKE :q", q: pattern)
    end
    records = records.order(wait: :desc) if @sort == "wait"
    records.includes(:pmm_material).order(fecha: :desc, llegada: :desc, id: :desc)
  end

  def clock(minutes)
    format("%02d:%02d", minutes / 60, minutes % 60)
  end

  private

  def dimension_values(key)
    column = DIMENSIONS.fetch(key).fetch(:column)
    @base.distinct.pluck(column).sort.map { |value| [ value, value ] }
  end

  def scope(except: nil)
    @scopes ||= {}
    @scopes[except] ||= begin
      records = @base.where(fecha: from..to)
      if time_from.positive? || time_to < 1440
        records = records.where("EXTRACT(EPOCH FROM llegada) >= ? AND EXTRACT(EPOCH FROM llegada) < ?", time_from * 60, time_to * 60)
      end
      @selected.except(except).each do |key, values|
        records = records.where(DIMENSIONS.fetch(key).fetch(:column).in(values)) if values.any?
      end
      records
    end
  end

  def breakdown(records, column)
    records.group(column).pluck(column, *ROW_METRICS).to_h { |key, count, average| [ key, [ count, average ] ] }
  end

  def hourly_chart
    data = breakdown(scope, HOUR_BUCKETS.fetch(band))
    starts = data.keys.min.step(data.keys.max, band)
    rows = starts.map do |start|
      first = [ start, time_from ].max
      last = [ start + band, time_to ].min
      point("#{clock(first)}–#{clock(last)}", data[start], time_from: first, time_to: last)
    end
    { title: "Por banda horaria de ingreso", rows: rows }
  end

  def date_chart
    first = [ from, first_date ].max
    last = [ to, last_date ].min
    selected_group = group
    if group == "auto"
      selected_group = case (last - first).to_i + 1
      when ..45 then "day"
      when ..200 then "week"
      else "month"
      end
    end
    data = breakdown(scope, DATE_BUCKETS.fetch(selected_group))
    rows = case selected_group
    when "day"
      (first..last).map { |date| point(date.strftime("%d/%m/%y"), data[date], from: date, to: date) }
    when "week"
      first.beginning_of_week(:monday).step(last, 7).map do |date|
        point(date.strftime("%d/%m/%y"), data[date], from: [ date, first ].max, to: [ date + 6, last ].min)
      end
    when "month"
      date = first.beginning_of_month
      [].tap do |items|
        while date <= last
          items << point(date.strftime("%m/%Y"), data[date], from: [ date, first ].max, to: [ date.end_of_month, last ].min)
          date = date.next_month
        end
      end
    end
    { title: "Por #{GROUPS.fetch(selected_group).downcase}", rows: rows }
  end

  def point(label, data, **changes)
    count, average = data || [ 0, nil ]
    { label: label, count: count, average: average, query: query(**changes) }
  end
end
