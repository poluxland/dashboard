import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["outcome", "severityFields", "severity", "followUpFields", "responsible", "dueOn"]

  connect() {
    this.update()
  }

  update() {
    const outcome = this.outcomeTarget.value
    const hasFinding = outcome === "corrected" || outcome === "follow_up"
    const needsFollowUp = outcome === "follow_up"

    this.severityFieldsTarget.hidden = !hasFinding
    this.severityFieldsTarget.disabled = !hasFinding
    this.severityTarget.required = hasFinding
    this.followUpFieldsTarget.hidden = !needsFollowUp
    this.followUpFieldsTarget.disabled = !needsFollowUp
    this.responsibleTarget.required = needsFollowUp
    this.dueOnTarget.required = needsFollowUp
  }
}
