import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["area", "person", "count"]

  connect() { this.updateCount() }

  addArea() {
    const area = this.areaTarget.value
    if (!area) return
    this.personTargets.forEach(person => {
      if (person.dataset.area === area) person.checked = true
    })
    this.updateCount()
  }

  updateCount() {
    const count = this.personTargets.filter(person => person.checked).length
    this.countTarget.textContent = `${count} personas seleccionadas`
  }
}
