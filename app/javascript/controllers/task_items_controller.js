import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]

  add() {
    this.listTarget.insertAdjacentHTML("beforeend", this.templateTarget.innerHTML.replaceAll("NEW_ITEM", crypto.randomUUID()))
  }

  remove(event) {
    const row = event.currentTarget.closest("[data-item-row]")
    row.querySelector('input[name$="[_destroy]"]').value = "1"
    row.hidden = true
    row.querySelectorAll("input:not([type=hidden])").forEach(input => input.required = false)
  }
}
