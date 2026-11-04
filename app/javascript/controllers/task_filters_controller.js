import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  apply() {
    this.element.requestSubmit()
  }
}
