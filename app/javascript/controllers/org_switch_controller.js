import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "button", "list" ]

  connect() {
    this.onKey = this.onKey.bind(this)
    this.onPointer = this.onPointer.bind(this)
  }

  disconnect() {
    this.stopListening()
  }

  toggle(event) {
    event.stopPropagation()
    if (this.expanded) {
      this.close()
    } else {
      this.open()
    }
  }

  get expanded() {
    return this.buttonTarget.getAttribute("aria-expanded") === "true"
  }

  open() {
    this.buttonTarget.setAttribute("aria-expanded", "true")
    this.listTarget.hidden = false
    document.addEventListener("click", this.onPointer)
    document.addEventListener("keydown", this.onKey)
    const current = this.listTarget.querySelector("[aria-current='true']")
    if (current) current.focus()
  }

  close() {
    this.buttonTarget.setAttribute("aria-expanded", "false")
    this.listTarget.hidden = true
    this.stopListening()
  }

  stopListening() {
    document.removeEventListener("click", this.onPointer)
    document.removeEventListener("keydown", this.onKey)
  }

  onKey(event) {
    if (event.key === "Escape") this.close()
  }

  onPointer(event) {
    if (this.element.contains(event.target)) return
    this.close()
  }
}
