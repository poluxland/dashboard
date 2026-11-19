import EnvasadoraDashboardController from "controllers/envasadora_dashboard_controller"

export default class extends EnvasadoraDashboardController {
  static targets = ["occupancy", "trend", "material", "error"]
  static values = { series: Object }

  drawCharts() {
    const { labels, latest, trend } = this.seriesValue
    const axis = { beginAtZero: true, suggestedMax: 140, ticks: { callback: value => `${value} %` } }
    const options = { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } } }

    this.charts.push(new window.Chart(this.occupancyTarget, {
      type: "bar",
      data: { labels, datasets: [{ label: "Ocupación (%)", data: latest, backgroundColor: "#2563eb", borderRadius: 4 }] },
      options: { ...options, indexAxis: "y", scales: { x: axis } }
    }))

    this.trendChart = new window.Chart(this.trendTarget, {
      type: "line",
      data: {
        labels: trend.map(point => point.date),
        datasets: [{ data: [], borderColor: "#2563eb", pointRadius: 2, spanGaps: false }]
      },
      options: {
        ...options,
        scales: { x: { ticks: { maxTicksLimit: 5, maxRotation: 0 } }, y: axis }
      }
    })
    this.charts.push(this.trendChart)
    this.updateTrend()
    this.element.dataset.chartsReady = "true"
  }

  updateTrend() {
    if (!this.trendChart) return

    const material = Number(this.materialTarget.value)
    const { labels, trend } = this.seriesValue
    const dataset = this.trendChart.data.datasets[0]
    dataset.label = `${labels[material]} (%)`
    dataset.data = trend.map(point => point.values[material])
    this.trendChart.update()
  }
}
