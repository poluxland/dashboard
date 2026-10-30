import { Controller } from "@hotwired/stimulus"

// Server-side aggregates also feed the accessible detail tables.
export default class extends Controller {
  static targets = ["production", "weekday", "pareto", "error"]
  static values = { charts: Object }

  async connect() {
    this.charts = []
    try {
      await this.loadChartLibrary()
      if (!this.element.isConnected) return
      this.drawCharts()
    } catch (_) {
      if (this.hasErrorTarget) this.errorTarget.hidden = false
    }
  }

  disconnect() {
    this.charts?.forEach(chart => chart.destroy())
  }

  loadChartLibrary() {
    if (window.Chart) return Promise.resolve()
    if (!window.envasadoraChartPromise) {
      window.envasadoraChartPromise = new Promise((resolve, reject) => {
        const script = document.createElement("script")
        script.src = "https://cdn.jsdelivr.net/npm/chart.js@4.4.3/dist/chart.umd.min.js"
        script.crossOrigin = "anonymous"
        script.onload = resolve
        script.onerror = () => {
          script.remove()
          window.envasadoraChartPromise = null
          reject(new Error("No se pudieron cargar los gráficos"))
        }
        document.head.appendChild(script)
      })
    }
    return window.envasadoraChartPromise
  }

  drawCharts() {
    const colors = ["#2563eb", "#16a34a", "#f59e0b"]
    const charts = this.chartsValue
    for (const name of ["production", "weekday"]) {
      const canvas = name === "production" ? this.productionTarget : this.weekdayTarget
      const data = charts[name]
      this.charts.push(new window.Chart(canvas, {
        type: "bar",
        data: {
          labels: data.labels,
          datasets: data.datasets.map((series, index) => ({ ...series, backgroundColor: colors[index] }))
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          interaction: { mode: "index", intersect: false },
          scales: {
            x: { stacked: name === "production", grid: { display: false } },
            y: { stacked: name === "production", beginAtZero: true, title: { display: true, text: "Sacos" } }
          },
          plugins: { tooltip: { callbacks: { label: context => `${context.dataset.label}: ${this.number(context.parsed.y)} sacos` } } }
        }
      }))
    }
    this.charts.push(new window.Chart(this.paretoTarget, {
      data: {
        labels: charts.pareto.labels,
        datasets: [
          { type: "bar", label: "Minutos detenidos", data: charts.pareto.minutes, backgroundColor: "#dc3545", yAxisID: "minutes" },
          { type: "line", label: "% acumulado", data: charts.pareto.cumulative, borderColor: "#2563eb", backgroundColor: "#2563eb", yAxisID: "percentage", tension: 0.15 }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: { ticks: { maxRotation: 55, callback: function(value) {
            const label = this.getLabelForValue(value)
            return label.length > 24 ? `${label.slice(0, 23)}…` : label
          } }, grid: { display: false } },
          minutes: { beginAtZero: true, title: { display: true, text: "Minutos" } },
          percentage: { position: "right", min: 0, max: 100, grid: { display: false }, ticks: { callback: value => `${value}%` } }
        }
      }
    }))
  }

  number(value) {
    return value == null ? "Sin reporte" : Number(value).toLocaleString("es-CL", { maximumFractionDigits: 1 })
  }
}
