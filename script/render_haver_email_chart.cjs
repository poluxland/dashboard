const { readFileSync } = require("node:fs")
const { createCanvas } = require("@napi-rs/canvas")
const { Chart } = require("chart.js/auto")

const numbers = new Intl.NumberFormat("es-CL", { maximumFractionDigits: 1 })
const tickLabel = value => numbers.format(value)
const font = { family: "DejaVu Sans, Arial, sans-serif", size: 16 }

function production(days) {
  return {
    height: 330,
    indexAxis: "x",
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
    scales: {
      x: { grid: { display: false }, ticks: { autoSkip: false, maxRotation: 0, font } },
      tons: {
        position: "left",
        beginAtZero: true,
        title: { display: true, text: "t", font },
        ticks: { maxTicksLimit: 5, callback: tickLabel, font },
        grid: { color: "#e4ebef" }
      },
      rate: {
        position: "right",
        beginAtZero: true,
        title: { display: true, text: "t/h", font },
        ticks: { maxTicksLimit: 5, callback: tickLabel, font },
        grid: { drawOnChartArea: false }
      }
    }
  }
}

function wrapCause(label) {
  const lines = label.match(/.{1,24}(?:\s|$)|.{1,24}/gu)?.map(line => line.trim()) || [label]
  return lines.length > 2 ? [lines[0], `${lines[1].slice(0, 23)}…`] : lines
}

function pareto(causes) {
  const labels = causes.map(cause => wrapCause(cause.label))
  const rowsHeight = labels.reduce((height, lines) => height + (lines.length > 1 ? 45 : 35), 0)
  return {
    height: Math.max(245, rowsHeight + 100),
    indexAxis: "y",
    data: {
      labels,
      datasets: [
        {
          type: "bar",
          label: "Minutos detenidos",
          data: causes.map(cause => cause.minutes),
          backgroundColor: "#dc3545",
          maxBarThickness: 19,
          borderRadius: 3,
          pointStyle: "rectRounded",
          xAxisID: "minutes",
          order: 1
        },
        {
          type: "line",
          label: "% acumulado",
          data: causes.map(cause => Math.min(cause.cumulative, 100)),
          borderColor: "#1d4ed8",
          backgroundColor: "#1d4ed8",
          borderWidth: 3,
          pointRadius: 4,
          xAxisID: "percentage",
          clip: false,
          order: 0
        }
      ]
    },
    scales: {
      y: { grid: { display: false }, ticks: { autoSkip: false, font } },
      minutes: {
        position: "bottom",
        beginAtZero: true,
        ticks: { maxTicksLimit: 5, callback: tickLabel, font },
        grid: { color: "#e4ebef" }
      },
      percentage: {
        position: "top",
        min: 0,
        max: 100,
        ticks: { stepSize: 25, callback: value => `${value}%`, font },
        grid: { drawOnChartArea: false }
      }
    }
  }
}

const { kind, rows } = JSON.parse(readFileSync(0, "utf8"))
const builders = { production, pareto }
const { height, indexAxis, data, scales } = builders[kind](rows)
const canvas = createCanvas(720, height)
const chart = new Chart(canvas.getContext("2d"), {
  type: "bar",
  data,
  options: {
    indexAxis,
    responsive: false,
    animation: false,
    devicePixelRatio: 2,
    layout: { padding: { left: 7, right: 11, bottom: 3 } },
    color: "#344957",
    plugins: {
      legend: {
        labels: { usePointStyle: true, pointStyleWidth: 14, font, padding: 16, sort: (a, b) => a.datasetIndex - b.datasetIndex }
      },
      tooltip: { enabled: false }
    },
    scales
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
