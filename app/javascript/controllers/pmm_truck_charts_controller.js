import EnvasadoraDashboardController from "controllers/envasadora_dashboard_controller"

export default class extends EnvasadoraDashboardController {
  static targets = ["canvas", "error"]
  static values = { charts: Array }

  drawCharts() {
    const palette = ["#2457A6", "#0F766E", "#CE671D", "#845BB3", "#576475", "#AA3A66",
      "#478623", "#A07E1C", "#2C8199", "#9D563A", "#5559B1", "#667842", "#904C49"]
    this.canvasTargets.forEach((canvas, index) => {
      const spec = this.chartsValue[index]
      const circular = spec.type === "doughnut"
      const hasMinutes = spec.series.some(series => series.axis === "minutes")
      this.charts.push(new window.Chart(canvas, {
        type: spec.type,
        data: {
          labels: spec.labels,
          datasets: spec.series.map(({ label, data, type, axis }, number) => ({
            label, data,
            ...(type ? { type, order: type === "line" ? 0 : 1 } : {}),
            ...(axis ? { yAxisID: axis } : {}),
            borderColor: palette[number % palette.length],
            backgroundColor: circular ? spec.labels.map((_, i) => palette[i % palette.length]) : palette[number % palette.length],
            pointRadius: 2
          }))
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          ...(circular ? {} : {
            interaction: { mode: "index", intersect: false },
            scales: {
              x: { stacked: Boolean(spec.stacked), grid: { display: false } },
              y: { stacked: Boolean(spec.stacked), beginAtZero: true,
                ...(hasMinutes ? { ticks: { precision: 0 }, title: { display: true, text: "Camiones" } } : {}) },
              ...(hasMinutes ? { minutes: { axis: "y", position: "right", beginAtZero: true,
                grid: { drawOnChartArea: false }, title: { display: true, text: "Minutos" } } } : {})
            }
          }),
          ...(spec.filterUrls ? {
            onHover: (_event, points) => { canvas.style.cursor = points.length ? "pointer" : "" },
            onClick: (_event, points) => {
              const url = spec.filterUrls[points[0]?.index]
              if (url) window.location.assign(url)
            }
          } : {}),
          plugins: { legend: { position: "bottom", labels: { boxWidth: 12 } } }
        }
      }))
    })
  }
}
