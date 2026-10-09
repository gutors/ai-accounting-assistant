import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "kind", "nfOnly" ]

  connect() {
    this.sync()
  }

  sync() {
    const showNf = this.kindTarget.value === "nota_fiscal"
    this.nfOnlyTargets.forEach((el) => {
      el.classList.toggle("hidden", !showNf)
      el.toggleAttribute("hidden", !showNf)
      el.querySelectorAll("input").forEach((input) => {
        input.disabled = !showNf
      })
    })
  }
}
