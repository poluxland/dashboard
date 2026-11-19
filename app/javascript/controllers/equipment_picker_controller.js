import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["search", "option", "empty"]

  filter() {
    const query = this.normalize(this.searchTarget.value.trim())
    let results = 0

    for (const option of this.optionTargets) {
      const matches = this.normalize(option.dataset.search).includes(query)
      const selected = option.querySelector("input").checked
      option.hidden = !matches && !selected
      if (matches) results += 1
    }

    this.emptyTarget.hidden = results > 0
  }

  normalize(text) {
    return text.toLowerCase().normalize("NFD").replace(/\p{Diacritic}/gu, "")
  }
}
