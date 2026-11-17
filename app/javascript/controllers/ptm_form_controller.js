import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["rows", "template"]
  add() {
    const key = `${Date.now()}_${this.rowsTarget.childElementCount}`
    this.rowsTarget.insertAdjacentHTML("beforeend", this.templateTarget.innerHTML.replaceAll("NEW_EVENT", key))
  }
  remove(event) {
    const row = event.target.closest("[data-event-row]")
    row.querySelector("[data-destroy]").value = "1"
    row.hidden = true
  }
}
