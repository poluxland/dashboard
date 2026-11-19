import EnvasadoraDashboardController from "controllers/envasadora_dashboard_controller"

export default class extends EnvasadoraDashboardController {
  static targets = ["horno", "temperature", "pressure", "error"]
  static values = { series: Object, from: Number, to: Number }

  drawCharts() {
    this.drawLine(this.hornoTarget, [["horno", "Alimentación horno (t/h)", "#2563eb"]])
    this.drawLine(this.temperatureTarget, [["presion5", "CC54 Temp", "#b45309"]])
    this.drawLine(this.pressureTarget, [
      ["presion1", "Ducto ascendente P1", "#2563eb"],
      ["presion2", "Ducto ascendente P2", "#15803d"],
      ["presion3", "CC54 P1", "#7e22ce"],
      ["presion4", "CC54 P2", "#b45309"],
      ["presion6", "Quench P1", "#be123c"]
    ])
    this.element.dataset.chartsReady = "true"
  }

  drawLine(canvas, fields) {
    const day = new Intl.DateTimeFormat("es-CL", { timeZone: "America/Santiago", month: "short", year: "numeric" })
    const detail = new Intl.DateTimeFormat("es-CL", { timeZone: "America/Santiago", dateStyle: "short", timeStyle: "short" })
    const datasets = fields.map(([key, label, color]) => ({
      label,
      data: this.seriesValue[key].map(([x, y]) => ({ x, y })),
      borderColor: color,
      backgroundColor: color,
      pointRadius: 1,
      pointHitRadius: 8,
      borderWidth: 1.5
    }))

    this.charts.push(new window.Chart(canvas, {
      type: "line",
      data: { datasets },
      options: {
        maintainAspectRatio: false,
        scales: {
          x: {
            type: "linear",
            min: this.fromValue,
            max: this.toValue,
            ticks: { maxTicksLimit: 6, maxRotation: 0, callback: value => day.format(value) }
          }
        },
        plugins: {
          legend: { display: fields.length > 1 },
          tooltip: { callbacks: { title: items => detail.format(items[0].parsed.x) } }
        }
      }
    }))
  }
}
