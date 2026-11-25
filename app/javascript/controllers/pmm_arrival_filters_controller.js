import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "error"]

  apply() {
    if (!this.valid()) return

    const form = this.formTarget
    if (form.requestSubmit) {
      form.requestSubmit()
    } else {
      form.submit()
    }
  }

  guard(event) {
    if (!this.valid()) event.preventDefault()
  }

  rememberFocus() {
    const active = document.activeElement
    this.focusedFieldId = this.formTarget.contains(active) ? active.id : null
  }

  restoreFocus() {
    if (this.focusedFieldId) {
      this.formTarget.elements.namedItem(this.focusedFieldId)?.focus({ preventScroll: true })
    }
    this.focusedFieldId = null
  }

  visitPage(event) {
    const { response, visit } = event.detail
    if (!response.redirected) return

    event.preventDefault()
    visit(response.url)
  }

  valid() {
    const { from, to, time_from, time_to } = this.formTarget.elements
    let message = ""
    if (!from.value || !to.value || from.valueAsNumber > to.valueAsNumber) {
      message = "Selecciona fechas válidas. La fecha inicial debe ser igual o anterior a la final."
    } else if (Number(time_from.value) >= Number(time_to.value)) {
      message = "La hora de ingreso desde debe ser anterior a la hora hasta."
    }

    this.errorTarget.textContent = message
    this.errorTarget.hidden = !message
    return !message && this.formTarget.checkValidity()
  }
}
