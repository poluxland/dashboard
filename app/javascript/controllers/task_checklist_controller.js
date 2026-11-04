import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async change(event) {
    const input = event.target
    if (input.type !== "checkbox") return
    const message = this.element.querySelector("[role=status]")
    input.disabled = true
    try {
      const response = await fetch(this.element.dataset.url, {
        method: "PATCH",
        headers: { "Content-Type": "application/json", Accept: "application/json", "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content },
        body: JSON.stringify({ task: { items_attributes: [{ id: input.dataset.itemId, completed: input.checked }] } })
      })
      if (!response.ok) throw new Error()
      const result = await response.json()
      input.closest("label").querySelector("[data-item-text]").classList.toggle("text-decoration-line-through", input.checked)
      this.element.querySelector("progress").value = result.completion_percentage
      this.element.querySelector("[data-progress-label]").textContent = `${result.completion_percentage}% completado`
      message.textContent = "Avance guardado."
    } catch {
      input.checked = !input.checked
      message.textContent = "No se pudo guardar el avance. Inténtalo nuevamente."
    } finally {
      input.disabled = false
    }
  }
}
