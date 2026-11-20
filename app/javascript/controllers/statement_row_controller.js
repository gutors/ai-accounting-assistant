import { Controller } from "@hotwired/stimulus"

const PDF_EXT = [ ".pdf" ]
const SPREADSHEET_EXT = [ ".csv", ".xlsx" ]

export default class extends Controller {
  static targets = [ "files", "form", "pdfInput", "spreadsheetInput", "trigger", "picker", "send", "discard" ]
  static values = { refusal: String, hint: String }

  connect() {
    this.pdf = null
    this.spreadsheet = null
    this.refused = false
    this.rendered = null
  }

  picked(event) {
    const chosen = Array.from(event.target.files || [])
    event.target.value = ""

    if (this.rendered === null) this.remember()

    let refused = false
    chosen.forEach((file) => {
      const kind = this.kindOf(file)
      if (kind === "pdf" && !this.pdf) {
        this.pdf = file
      } else if (kind === "spreadsheet" && !this.spreadsheet) {
        this.spreadsheet = file
      } else if (!kind) {
        refused = true
      }
    })

    this.refused = refused
    this.sync()
  }

  discard(event) {
    event.preventDefault()
    this.pdf = null
    this.spreadsheet = null
    this.refused = false
    if (this.rendered === null) this.remember()
    this.release()
  }

  send(event) {
    event.preventDefault()
    this.fill(this.pdfInputTarget, this.pdf)
    this.fill(this.spreadsheetInputTarget, this.spreadsheet)
    this.formTarget.requestSubmit()
  }

  fill(input, file) {
    if (!file) {
      input.value = ""
      return
    }

    const transfer = new DataTransfer()
    transfer.items.add(file)
    input.files = transfer.files
  }

  sync() {
    if (this.rendered === null) this.remember()
    this.lines()
    this.visibility()
  }

  release() {
    this.filesTarget.innerHTML = this.rendered
    this.visibility()
  }

  remember() {
    this.rendered = this.filesTarget.innerHTML
    this.renderedEmpty = !this.rendered.includes("statement-file")
  }

  visibility() {
    const staged = Boolean(this.pdf || this.spreadsheet)

    this.triggerTarget.hidden = Boolean(this.spreadsheet)
    this.sendTarget.hidden = !this.spreadsheet
    this.discardTarget.hidden = !staged
  }

  lines() {
    this.filesTarget.replaceChildren()

    if (this.refused) {
      this.filesTarget.append(this.refusalLine())
    }

    if (this.pdf) {
      this.filesTarget.append(this.line(`Pdf ${this.pdf.name}`))
    }

    if (this.spreadsheet) {
      this.filesTarget.append(this.line(`Planilha ${this.spreadsheet.name}`))
    } else if (this.renderedEmpty) {
      this.filesTarget.append(this.hintLine())
    }
  }

  line(text) {
    const node = document.createElement("p")
    node.className = "statement-file"
    node.title = text
    node.textContent = text
    return node
  }

  hintLine() {
    const node = document.createElement("p")
    node.className = "statement-hint"
    node.textContent = this.hintValue
    return node
  }

  refusalLine() {
    const node = document.createElement("p")
    node.className = "statement-refusal"
    node.textContent = this.refusalValue
    return node
  }

  kindOf(file) {
    const name = (file.name || "").toLowerCase()
    if (PDF_EXT.some((ext) => name.endsWith(ext))) return "pdf"
    if (SPREADSHEET_EXT.some((ext) => name.endsWith(ext))) return "spreadsheet"
    return null
  }
}
