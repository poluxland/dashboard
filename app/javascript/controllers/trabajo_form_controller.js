import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "total"]

  update(event) {
    if (!event.target.matches("[data-item-quantity], [data-item-price]")) return

    const money = new Intl.NumberFormat("es-CL", { style: "currency", currency: "CLP" })
    let total = 0
    for (const row of this.rowTargets) {
      const quantity = Number(row.querySelector("[data-item-quantity]").value)
      const price = Number(row.querySelector("[data-item-price]").value)
      const subtotal = quantity * price
      row.querySelector("[data-item-subtotal]").textContent = money.format(subtotal)
      total += subtotal
    }
    this.totalTarget.textContent = money.format(total)
  }
}
