import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "kind", "nfOnly" ]

  connect() {
    this.sync()
  }

  sync() {
    const recibo = this.kindTarget.value === "recibo"
    this.nfOnlyTargets.forEach((el) => {
      el.classList.toggle("hidden", recibo)
      el.toggleAttribute("hidden", recibo)
      el.querySelectorAll("input").forEach((input) => {
        input.disabled = recibo
      })
    })
  }
}
