import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  start(event) {
    if (this.saving || event.target.closest("a, button, input, select, textarea")) {
      event.preventDefault()
      return
    }
    this.card = event.target.closest("[data-task-card]")
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", this.card.dataset.taskUrl)
    this.card.classList.add("opacity-50")
  }

  over(event) {
    if (!this.card || this.saving) return
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
    event.currentTarget.classList.add("border", "border-primary")
  }

  leave(event) {
    if (!event.currentTarget.contains(event.relatedTarget)) {
      event.currentTarget.classList.remove("border", "border-primary")
    }
  }

  end() {
    this.card?.classList.remove("opacity-50")
    this.element.querySelectorAll("[data-task-status]").forEach(column => column.classList.remove("border", "border-primary"))
    this.card = null
  }

  async drop(event) {
    event.preventDefault()
    const card = this.card
    const status = event.currentTarget.dataset.taskStatus
    this.end()
    if (!card || this.saving || card.dataset.taskStatus === status) return
    this.saving = true
    const message = this.element.querySelector("[role=status]")
    message.textContent = "Guardando cambio…"
    try {
      const response = await fetch(card.dataset.taskUrl, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ task: { status } })
      })
      if (!response.ok) throw new Error("No se pudo guardar")
      await response.json()
      window.location.reload()
    } catch {
      message.textContent = "No se pudo mover la tarea. Inténtalo nuevamente o recarga la página."
      this.saving = false
    }
  }
}
