module PmmTrucksHelper
  def pmm_time(value)
    value&.strftime("%H:%M")
  end

  def pmm_metric(value)
    value.nil? ? "—" : number_with_precision(value, precision: 1, strip_insignificant_zeros: true)
  end

  def pmm_compliance(count, within)
    count.positive? ? number_to_percentage(100.0 * within / count, precision: 1) : "—"
  end

  def pmm_arrival_chart_data(chart)
    rows = chart.fetch(:rows)
    {
      type: "bar", labels: rows.pluck(:label),
      filterUrls: rows.map { |row| arrivals_pmm_trucks_path(row.fetch(:query)) },
      series: [
        { label: "Camiones", data: rows.pluck(:count), type: "bar" },
        { label: "Espera promedio (min)", data: rows.map { |row| row[:average]&.round(1)&.to_f }, type: "line", axis: "minutes" }
      ]
    }
  end
end
