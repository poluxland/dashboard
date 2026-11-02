import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["date", "shift", "hours", "limit"]
  static values = { maximum: Number, schedule: Object }

  connect() { this.updateLimits() }

  updateLimits() {
    const date = this.dateTarget.value
    const day = date ? new Date(`${date}T12:00:00Z`).getUTCDay() : null
    const shift = this.shiftTarget.value
    const offsets = this.scheduleValue[day === 0 ? 7 : day]?.[shift]
    const maximum = day === null || !shift ? this.maximumValue : offsets ? offsets[1] - offsets[0] : 0
    this.hoursTargets.forEach(input => { input.max = String(maximum) })
    this.limitTarget.textContent = `Horas entre 0 y ${maximum}. Usa decimales, por ejemplo 6,5.`
  }
}
