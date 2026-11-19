import EnvasadoraDashboardController from "controllers/envasadora_dashboard_controller"

export default class extends EnvasadoraDashboardController {
  static targets = ["canvas", "error"]
  static values = { series: Array, from: String, to: String }

  drawCharts() {
    if (!this.hasCanvasTarget) return

    const colors = ["#2563eb", "#16804a", "#a84e0d", "#7347ab"]
    const date = new Intl.DateTimeFormat("es-CL", { timeZone: "UTC", day: "numeric", month: "short", year: "numeric" })
    const money = new Intl.NumberFormat("es-CL", { style: "currency", currency: "CLP" })

    this.charts.push(new window.Chart(this.canvasTarget, {
      type: "line",
      data: {
        datasets: this.seriesValue
          .filter(series => series.data.length > 0)
          .map(series => {
            const color = colors[this.seriesValue.findIndex(item => item.label === series.label)]
            return {
              label: series.label,
              data: series.data.map(([day, total]) => ({ x: Date.parse(day), y: total })),
              borderColor: color,
              backgroundColor: color,
              pointRadius: 2,
              pointHitRadius: 8
            }
          })
      },
      options: {
        maintainAspectRatio: false,
        scales: {
          x: {
            type: "linear",
            min: Date.parse(this.fromValue),
            max: Date.parse(this.toValue),
            ticks: { maxTicksLimit: 6, maxRotation: 0, callback: value => date.format(value) }
          },
          y: { beginAtZero: true, ticks: { callback: value => money.format(value) } }
        },
        plugins: {
          tooltip: {
            callbacks: {
              title: items => date.format(items[0].parsed.x),
              label: item => `${item.dataset.label}: ${money.format(item.parsed.y)}`
            }
          }
        }
      }
    }))
  }
}
