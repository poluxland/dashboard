import EnvasadoraDashboardController from "controllers/envasadora_dashboard_controller"

export default class extends EnvasadoraDashboardController {
  static targets = ["production", "indicators", "broken", "error"]
  static values = { days: Array }

  drawCharts() {
    const days = this.daysValue
    const labels = days.map(day => {
      const [, month, date] = day.date.split("-")
      return `${date}/${month}`
    })
    const series = (label, key, color, options = {}) => ({
      label, data: days.map(day => day[key]), borderColor: color,
      backgroundColor: color, spanGaps: false, ...options
    })
    this.addChart(this.productionTarget, labels, [
      series("Producción (t)", "tons", "#93c5fd", { type: "bar", yAxisID: "tons" }),
      series("Rendimiento (%)", "performance", "#2563eb", { type: "line", yAxisID: "rate" })
    ], {
      tons: { beginAtZero: true, title: { display: true, text: "Toneladas" } },
      rate: { position: "right", beginAtZero: true, grid: { drawOnChartArea: false }, title: { display: true, text: "Rendimiento %" } }
    })
    this.addChart(this.indicatorsTarget, labels, [
      series("Disponibilidad + fallas", "availability_plus", "#2563eb"),
      series("Disponibilidad − fallas", "availability_minus", "#64748b", { borderDash: [5, 4] }),
      series("Confiabilidad", "reliability", "#16a34a"),
      series("OEE", "oee", "#d97706")
    ], { y: { beginAtZero: true, title: { display: true, text: "%" } } })
    this.addChart(this.brokenTarget, labels, [series("Sacos rotos", "broken", "#dc3545")], {
      y: { beginAtZero: true, title: { display: true, text: "% de sacos producidos" } }
    })
  }

  addChart(canvas, labels, datasets, scales) {
    this.charts.push(new window.Chart(canvas, {
      type: "line", data: { labels, datasets },
      options: { responsive: true, maintainAspectRatio: false, scales,
        interaction: { mode: "index", intersect: false },
        plugins: { tooltip: { callbacks: { label: context => `${context.dataset.label}: ${this.number(context.parsed.y)}` } } }
      }
    }))
  }
}
