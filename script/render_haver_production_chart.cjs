const { readFileSync } = require("node:fs")
const { createCanvas } = require("@napi-rs/canvas")
const { Chart } = require("chart.js/auto")

const days = JSON.parse(readFileSync(0, "utf8"))
const canvas = createCanvas(720, 330)
const numbers = new Intl.NumberFormat("es-CL", { maximumFractionDigits: 1 })
const tickLabel = value => numbers.format(value)
const labelFont = { family: "DejaVu Sans, Arial, sans-serif", size: 18 }
const chart = new Chart(canvas.getContext("2d"), {
  type: "bar",
  data: {
    labels: days.map(day => day.label),
    datasets: [
      {
        type: "bar",
        label: "Producción (t)",
        data: days.map(day => day.tons),
        backgroundColor: "#93c5fd",
        maxBarThickness: 44,
        borderRadius: 3,
        pointStyle: "rectRounded",
        yAxisID: "tons",
        order: 1
      },
      {
        type: "line",
        label: "Rendimiento (t/h)",
        data: days.map(day => day.rate),
        borderColor: "#1d4ed8",
        backgroundColor: "#1d4ed8",
        borderWidth: 3,
        pointRadius: 4,
        spanGaps: false,
        yAxisID: "rate",
        order: 0
      }
    ]
  },
  options: {
    responsive: false,
    animation: false,
    devicePixelRatio: 2,
    layout: { padding: { left: 7, right: 7, bottom: 3 } },
    color: "#344957",
    plugins: {
      legend: {
        labels: { usePointStyle: true, font: labelFont, padding: 20, sort: (a, b) => a.datasetIndex - b.datasetIndex }
      },
      tooltip: { enabled: false }
    },
    scales: {
      x: { grid: { display: false }, ticks: { autoSkip: false, maxRotation: 0, font: labelFont } },
      tons: {
        position: "left",
        beginAtZero: true,
        title: { display: true, text: "t", font: labelFont },
        ticks: { maxTicksLimit: 5, callback: tickLabel, font: labelFont },
        grid: { color: "#e4ebef" }
      },
      rate: {
        position: "right",
        beginAtZero: true,
        title: { display: true, text: "t/h", font: labelFont },
        ticks: { maxTicksLimit: 5, callback: tickLabel, font: labelFont },
        grid: { drawOnChartArea: false }
      }
    }
  },
  plugins: [{
    id: "solidBackground",
    beforeDraw(chart) {
      const ctx = chart.ctx
      ctx.save()
      ctx.fillStyle = "#ffffff"
      ctx.fillRect(0, 0, chart.width, chart.height)
      ctx.restore()
    }
  }]
})

process.stdout.write(canvas.toBuffer("image/png"))
chart.destroy()
