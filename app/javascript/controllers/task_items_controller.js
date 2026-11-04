import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]

  add() {
    this.nextIndex = Math.max(Date.now(), (this.nextIndex || 0) + 1)
    this.listTarget.insertAdjacentHTML("beforeend", this.templateTarget.innerHTML.replaceAll("NEW_ITEM", String(this.nextIndex)))
  }

  remove(event) {
    const row = event.currentTarget.closest("[data-item-row]")
    row.querySelector('input[name$="[_destroy]"]').value = "1"
    row.hidden = true
    row.querySelectorAll("input:not([type=hidden])").forEach(input => input.required = false)
  }
}
