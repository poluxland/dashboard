class PmmTruckReport
  MONTHS = %w[Ene Feb Mar Abr May Jun Jul Ago Sep Oct Nov Dic].freeze
  MONTH_EXPR = "EXTRACT(MONTH FROM pmm_trucks.fecha)::integer".freeze
  WAIT_SUMMARY = [
    Arel.sql("COUNT(*)"),
    Arel.sql("AVG(pmm_trucks.wait)"),
    Arel.sql("COUNT(*) FILTER (WHERE pmm_trucks.wait <= 60)")
  ].freeze

  attr_reader :today

  def initialize(today)
    @today = today
  end

  def years
    [ today.year, *PmmTruck.where.not(fecha: nil).distinct.pluck(Arel.sql("EXTRACT(YEAR FROM fecha)::integer")) ].uniq.sort.reverse
  end

  def periods
    {
      "Hoy" => today..today,
      "Ayer" => today.yesterday..today.yesterday,
      "Mes actual" => today.all_month,
      "Mes anterior" => today.prev_month.all_month
    }.transform_values do |range|
      scope = measured(range)
      eligible = scope.where(tipo: [ "BRU", "Batea 20", "Batea 40" ]).group(:tipo).count
      { results: by_material(scope), totals: scope.pluck(*WAIT_SUMMARY).first, bru_eligible: eligible.values.sum, bru: eligible.fetch("BRU", 0) }
    end
  end

  def report_charts
    daily_scope = measured(today.all_month)
    annual_scope = measured(today.all_year)
    daily = wait_buckets(daily_scope, :fecha)
    monthly = wait_buckets(annual_scope, Arel.sql(MONTH_EXPR))
    daily_average = daily_scope.joins(:pmm_material).group("pmm_materials.nombre", :fecha).average(:wait)
    bru = PmmBruVisit.where.not(fecha: nil)
    bru_day = bru.group(:fecha).count.sort
    [
      grouped_wait_chart("Camiones por día", (1..today.end_of_month.day).map { |day| Date.new(today.year, today.month, day) }, daily) { |date| date.strftime("%d/%m") },
      grouped_wait_chart("Cumplimiento diario", (1..today.end_of_month.day).map { |day| Date.new(today.year, today.month, day) }, daily, percentages: true) { |date| date.strftime("%d/%m") },
      grouped_wait_chart("Camiones por mes", (1..12).to_a, monthly) { |month| MONTHS[month - 1] },
      grouped_wait_chart("Cumplimiento mensual", (1..12).to_a, monthly, percentages: true) { |month| MONTHS[month - 1] },
      {
        title: "Espera diaria por materia prima", type: "line",
        labels: today.all_month.map { |date| date.strftime("%d/%m") },
        series: daily_average.keys.map(&:first).uniq.sort_by(&:to_s).map do |material|
          { label: material.presence || "Sin nombre", data: today.all_month.map { |date| daily_average[[ material, date ]]&.round(1)&.to_f } }
        end
      },
      distribution_chart("Camiones por tipo", annual_scope.group(:tipo).count),
      {
        title: "Registros BRU por día", type: "line",
        labels: bru_day.map { |date, _| date.strftime("%d/%m/%Y") },
        series: [ { label: "Registros BRU", data: bru_day.map(&:last) } ]
      },
      distribution_chart("BRU por día de la semana", bru.group(Arel.sql("EXTRACT(ISODOW FROM fecha)::integer")).count.transform_keys do |day|
        %w[Lun Mar Mié Jue Vie Sáb Dom][day - 1]
      end),
      distribution_chart("BRU por materia prima", bru.group(:mmpp).count)
    ]
  end

  def annual(year)
    scope = measured(Date.new(year, 1, 1).all_year)
    material = scope.joins(:pmm_material)
    conchuela = material.where("LOWER(pmm_materials.nombre) = ?", "conchuela")
    flatbed = scope.where("LOWER(tipo) = ?", "plano")
    materials = monthly_groups(material, "pmm_materials.nombre")
    conchuela_monthly = monthly_groups(conchuela, "pmm_trucks.tipo")
    flatbed_avg = flatbed.group(Arel.sql(MONTH_EXPR)).average(:wait)
    flatbed_stats = flatbed.pluck(Arel.sql("AVG(wait)"), Arel.sql("PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY wait)"), Arel.sql("STDDEV_SAMP(wait)")).first
    average, _, deviation = flatbed_stats
    outliers = flatbed.where("wait > ?", average + 3 * deviation).count if average && deviation
    {
      totals: scope.pluck(*WAIT_SUMMARY).first, flatbed: flatbed.pluck(*WAIT_SUMMARY).first,
      flatbed_stats: flatbed_stats, flatbed_outliers: outliers,
      materials: materials, conchuela: conchuela_monthly,
      charts: [
        compliance_chart("Cumplimiento de espera", scope),
        distribution_chart("Conchuela por tipo", conchuela.group(:tipo).count),
        compliance_chart("Cumplimiento de camiones planos", flatbed),
        monthly_average_chart("Espera mensual por materia prima", materials),
        monthly_average_chart("Espera mensual · comparación de materias primas", materials, type: "bar"),
        { title: "Espera mensual de camiones planos", type: "line", labels: MONTHS,
          series: [ { label: "Espera (min)", data: (1..12).map { |month| flatbed_avg[month]&.round(1)&.to_f } } ] }
      ]
    }
  end

  private

  def measured(range)
    PmmTruck.measured.where(fecha: range)
  end

  def by_material(scope)
    scope.joins(:pmm_material).group("pmm_materials.nombre").order("pmm_materials.nombre").pluck("pmm_materials.nombre", *WAIT_SUMMARY)
  end

  def monthly_groups(scope, field)
    scope.group(field, Arel.sql(MONTH_EXPR)).pluck(field, Arel.sql(MONTH_EXPR), *WAIT_SUMMARY)
      .group_by(&:first).transform_values { |rows| rows.to_h { |_, month, count, average, within| [ month, { count: count, average: average, within: within } ] } }
  end

  def wait_buckets(scope, field)
    scope.group(field).pluck(field, *WAIT_SUMMARY).to_h { |key, total, _, within| [ key, [ within, total - within ] ] }
  end

  def grouped_wait_chart(title, keys, buckets, percentages: false, &formatter)
    values = keys.map do |key|
      counts = buckets.fetch(key, [ 0, 0 ])
      percentages && counts.sum.positive? ? counts.map { |count| (100.0 * count / counts.sum).round(1) } : counts
    end
    { title: title, type: "bar", labels: keys.map(&formatter), stacked: true,
      series: [ { label: "Hasta 60 min", data: values.map(&:first) }, { label: "Más de 60 min", data: values.map(&:last) } ] }
  end

  def compliance_chart(title, scope)
    total, _, within = scope.pluck(*WAIT_SUMMARY).first
    distribution_chart(title, { "Hasta 60 min" => within, "Más de 60 min" => total - within })
  end

  def distribution_chart(title, data)
    { title: title, type: "doughnut", labels: data.keys.map { |name| name.presence || "Sin registro" },
      series: [ { label: title, data: data.values } ] }
  end

  def monthly_average_chart(title, groups, type: "line")
    series = groups.sort_by { |name, _| name.to_s }.map do |name, buckets|
      { label: name.presence || "Sin nombre", data: (1..12).map { |month| buckets.dig(month, :average)&.round(1)&.to_f } }
    end
    { title: title, type: type, labels: MONTHS, series: series }
  end
end
