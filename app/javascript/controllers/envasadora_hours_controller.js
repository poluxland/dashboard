import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["date", "shift", "hours", "limit"]
  static values = { maximum: Number, saturday: Number }

  connect() { this.updateLimits() }

  updateLimits() {
    const date = this.dateTarget.value
    const saturday = date && new Date(`${date}T12:00:00Z`).getUTCDay() === 6
    const maximum = saturday && this.shiftTarget.value === "TM" ? this.saturdayValue : this.maximumValue
    this.hoursTargets.forEach(input => { input.max = String(maximum) })
    this.limitTarget.textContent = `Horas entre 0 y ${maximum}. Usa decimales, por ejemplo 6,5.`
  }
}
