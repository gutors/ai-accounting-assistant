import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const timeoutMs = Number(this.element.dataset.toastTimeoutMs)
    this.timeoutId = window.setTimeout(() => this.dismiss(), timeoutMs)
  }

  disconnect() {
    window.clearTimeout(this.timeoutId)
  }

  dismiss() {
    this.element.remove()
  }
}
