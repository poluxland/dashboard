import HaverDashboardController from "controllers/haver_dashboard_controller"

export default class extends HaverDashboardController {
  static targets = ["daily", "weekly", "monthly", "error"]
  static values = { charts: Object }

  drawCharts() {
    const { days, weeks, months } = this.chartsValue
    const series = (label, rows, key, color, options = {}) => ({ label,
      data: rows.map(row => row[key]), borderColor: color, backgroundColor: color,
      spanGaps: false, ...options })
    const scales = { y: { beginAtZero: true, title: { display: true, text: "Toneladas" } } }
    this.addChart(this.dailyTarget, days.map(row => row.date), [
      series("Traslado diario (t)", days, "tons", "#93c5fd", { type: "bar" }),
      series("Promedio móvil de 7 días (t/día)", days, "average", "#2563eb")
    ], scales)
    for (const [canvas, rows] of [[this.weeklyTarget, weeks], [this.monthlyTarget, months]]) {
      this.addChart(canvas, rows.map(row => row.date), [series("Total trasladado (t)", rows, "tons", "#2563eb", { type: "bar" })], scales)
    }
    this.element.dataset.chartsReady = "true"
  }
}
