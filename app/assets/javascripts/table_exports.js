(() => {
  const toolbarSelector = "[data-table-export-toolbar]"
  const excluded = "[hidden], [aria-hidden='true'], .d-none, .visually-hidden, .sr-only, button, .btn"
  const dataInputs = "input, select, textarea"

  function cellText(cell) {
    const copy = cell.cloneNode(true)
    const inputs = Array.from(cell.querySelectorAll(dataInputs))
    copy.querySelectorAll(dataInputs).forEach((node, index) => {
      const input = inputs[index]
      let value = ""
      if (input.tagName === "SELECT") {
        value = Array.from(input.selectedOptions).map(option => option.textContent.trim()).join(", ")
      } else if (!["checkbox", "radio", "hidden", "submit", "reset", "button", "password", "file"].includes(input.type)) {
        value = input.value
      }
      node.replaceWith(document.createTextNode(value))
    })
    copy.querySelectorAll(excluded).forEach(node => node.remove())
    copy.querySelectorAll("br, div, p, li").forEach(node => node.after(" "))
    return copy.textContent.replace(/\s+/g, " ").trim()
  }

  function readTable(table) {
    const source = Array.from(table.rows).filter(row => !row.hidden && getComputedStyle(row).display !== "none")
    const headers = source.filter(row => row.parentElement === table.tHead).length
    const rows = source.map(() => [])
    const actionColumns = new Set()
    const sectionEnds = new Map(source.map((row, index) => [row.parentElement, index + 1]))

    source.forEach((row, index) => {
      let column = 0
      Array.from(row.cells).forEach(cell => {
        while (rows[index][column] !== undefined) column += 1
        const value = cellText(cell)
        const isAction = index < headers && /^acci[oó]n(?:es)?$/i.test(value)
        const remaining = sectionEnds.get(row.parentElement) - index
        const rowSpan = Math.min(cell.rowSpan || remaining, remaining)
        for (let x = 0; x < cell.colSpan; x += 1) {
          if (isAction) actionColumns.add(column + x)
          for (let y = 0; y < rowSpan; y += 1) {
            rows[index + y][column + x] = x === 0 && y === 0 && !isAction ? value : ""
          }
        }
        column += cell.colSpan
      })
    })

    const width = rows.reduce((size, row) => Math.max(size, row.length), 0)
    const columns = Array.from({ length: width }, (_, index) => index)
      .filter(index => !actionColumns.has(index) && rows.some(row => row[index]))
    return { rows: rows.map(row => columns.map(index => row[index] || "")), headers }
  }

  function titleFor(table, index) {
    if (table.caption?.textContent.trim()) return table.caption.textContent.trim()
    const section = table.closest("section, details, article")
    const heading = section?.querySelector("summary, h2, h3, h4, h5, h6") || document.querySelector("h1")
    const label = table.getAttribute("aria-label") || section?.getAttribute("aria-label") || heading?.textContent.trim()
    return `${label || "Tabla"} ${index + 1}`
  }

  function addButtons() {
    document.querySelectorAll("table").forEach((table, index) => {
      if (table.closest('[data-table-export="off"]') || table.querySelector("table") || !table.tBodies.length) return
      if (table.rows.length === 0) return

      const parent = table.parentElement
      const placement = parent.classList.contains("table-responsive") && parent.children.length === 1 ? parent : table
      if (placement.previousElementSibling?.matches(toolbarSelector)) return

      const toolbar = document.createElement("div")
      toolbar.dataset.tableExportToolbar = ""
      toolbar.className = "d-flex flex-wrap align-items-center gap-2 mb-2 d-print-none"

      const button = document.createElement("button")
      button.type = "button"
      button.dataset.downloadTable = ""
      button.dataset.tableTitle = titleFor(table, index)
      button.className = "btn btn-sm btn-outline-success"
      button.setAttribute("aria-label", `Descargar Excel · ${button.dataset.tableTitle}`)
      button.textContent = "Descargar Excel"

      const status = document.createElement("span")
      status.setAttribute("role", "status")
      status.className = "small text-danger"
      toolbar.append(button, status)
      placement.before(toolbar)
    })
  }

  async function download(button) {
    const toolbar = button.closest(toolbarSelector)
    const placement = toolbar.nextElementSibling
    const table = placement.matches("table") ? placement : placement.querySelector("table")
    const status = toolbar.querySelector("[role='status']")
    const endpoint = document.querySelector("meta[name='table-export-url']").content
    const token = document.querySelector("meta[name='csrf-token']")?.content || ""
    button.disabled = true
    status.textContent = ""

    try {
      const { rows, headers } = readTable(table)
      if (!rows[0]?.length) {
        status.textContent = "No hay datos visibles para descargar."
        return
      }

      const response = await fetch(endpoint, {
        method: "POST",
        credentials: "same-origin",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": token },
        body: JSON.stringify({ table_export: { title: button.dataset.tableTitle, rows, headers } })
      })

      if (!response.ok) {
        status.textContent = response.status === 413 || response.status === 422
          ? "La tabla supera el tamaño admitido para una descarga."
          : "No se pudo descargar la tabla. Vuelve a intentarlo."
        return
      }

      const file = await response.blob()
      const url = URL.createObjectURL(file)
      const link = document.createElement("a")
      link.href = url
      link.download = response.headers.get("Content-Disposition")?.match(/filename="([^"]+)"/)?.[1] || "tabla.xlsx"
      document.body.append(link)
      link.click()
      link.remove()
      setTimeout(() => URL.revokeObjectURL(url), 1000)
    } catch (_) {
      status.textContent = "No se pudo descargar la tabla. Vuelve a intentarlo."
    } finally {
      button.disabled = false
    }
  }

  document.addEventListener("click", event => {
    const button = event.target.closest("[data-download-table]")
    if (button) download(button)
  })
  document.addEventListener("DOMContentLoaded", addButtons)
  document.addEventListener("turbo:load", addButtons)
  document.addEventListener("turbo:frame-load", addButtons)
})()
