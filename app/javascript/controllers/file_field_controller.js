import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "empty", "filename" ]

  picked(event) {
    this.show(event.target.files && event.target.files[0])
  }

  cleared() {
    this.show(null)
  }

  show(file) {
    if (file) {
      this.emptyTarget.hidden = true
      this.filenameTarget.hidden = false
      this.filenameTarget.textContent = file.name
    } else {
      this.emptyTarget.hidden = false
      this.filenameTarget.hidden = true
      this.filenameTarget.textContent = ""
    }
  }
}
