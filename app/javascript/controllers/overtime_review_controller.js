import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["all", "item", "reason"]

  connect() {
    if (this.hasReasonTarget) this.setReasonVisible(false)
    this.updateAll()
  }

  toggleAll() {
    this.itemTargets.forEach((item) => { item.checked = this.allTarget.checked })
    this.updateAll()
  }

  updateAll() {
    if (!this.hasAllTarget) return

    const checked = this.itemTargets.filter((item) => item.checked).length
    this.allTarget.checked = checked > 0 && checked === this.itemTargets.length
    this.allTarget.indeterminate = checked > 0 && checked < this.itemTargets.length
  }

  showReason(event) {
    this.setReasonVisible(event.target.value === "Rechazada")
  }

  setReasonVisible(visible) {
    const input = this.reasonTarget.querySelector("input")
    this.reasonTarget.hidden = !visible
    input.required = visible
    input.disabled = !visible
  }
}
