import HaverDashboardController from "controllers/haver_dashboard_controller"

export default class extends HaverDashboardController {
  static targets = ["production", "stops", "shifts", "availability", "equipment", "causes", "error"]
  static values = { charts: Object }
  drawCharts() {
    const { days, shifts, equipment, causes } = this.chartsValue
    const labels = days.map(day => day.date)
    const series = (label, rows, key, color, options = {}) => ({ label, data: rows.map(row => row[key]), borderColor: color, backgroundColor: color, ...options })
    this.addChart(this.productionTarget, labels, [
      series("Producción (t)", days, "tons", "#93c5fd", { type: "bar", yAxisID: "tons" }),
      series("Rendimiento (ton/h de turno)", days, "rate", "#2563eb", { yAxisID: "rate" })
    ], { tons: { beginAtZero: true }, rate: { beginAtZero: true, position: "right", grid: { drawOnChartArea: false } } })
    this.addChart(this.stopsTarget, labels, [series("Detenciones (min)", days, "minutes", "#f59e0b", { type: "bar" })], { y: { beginAtZero: true } })
    this.addChart(this.shiftsTarget, shifts.map(row => row.shift), [series("Producción (t)", shifts, "tons", "#2563eb", { type: "bar" })], { y: { beginAtZero: true } })
    this.addChart(this.availabilityTarget, labels, [series("Tiempo sin detenciones (%)", days, "available", "#16a34a")], { y: { beginAtZero: true, max: 100 } })
    for (const [canvas, rows] of [[this.equipmentTarget, equipment], [this.causesTarget, causes]]) {
      const top = rows.slice(0, 10)
      if (rows.length > 10) top.push({ label: "Otros", minutes: rows.slice(10).reduce((sum, row) => sum + row.minutes, 0), cumulative: 100 })
      this.addChart(canvas, top.map(row => row.label), [
        series("Minutos", top, "minutes", "#93c5fd", { type: "bar", yAxisID: "minutes" }),
        series("% acumulado", top, "cumulative", "#dc3545", { yAxisID: "percent" })
      ], { minutes: { beginAtZero: true }, percent: { beginAtZero: true, max: 100, position: "right", grid: { drawOnChartArea: false } } })
    }
    this.element.dataset.chartsReady = "true"
  }
}
