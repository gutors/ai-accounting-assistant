import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "sumPayments", "sumDocuments", "verdict" ]

  connect() {
    this.recompute()
  }

  toggle() {
    this.recompute()
  }

  applySuggestion(event) {
    event.preventDefault()
    const button = event.currentTarget
    this.clearChecks()
    this.checkPayment(button.dataset.paymentId)
    ;(button.dataset.documentIds || "").split(",").filter(Boolean).forEach((id) => this.checkDocument(id))
    this.recompute()
    if (this.equalSums()) this.element.querySelector("#match-confirm")?.requestSubmit()
  }

  recompute() {
    const pays = this.checkedRows('[data-row="payment"]')
    const docs = this.checkedRows('[data-row="pool-document"]')
    const payCents = this.cents(pays)
    const docCents = this.cents(docs)
    this.sumPaymentsTarget.textContent = this.format(payCents)
    this.sumDocumentsTarget.textContent = this.format(docCents)
    if (pays.length === 0 || docs.length === 0) {
      this.verdictTarget.textContent = ""
    } else if (docCents < payCents) {
      this.verdictTarget.textContent = "Documentos somam menos"
    } else if (docCents === payCents) {
      this.verdictTarget.textContent = "Soma igual"
    } else {
      this.verdictTarget.textContent = "Documentos somam mais"
    }
  }

  checkedRows(selector) {
    return Array.from(this.element.querySelectorAll(selector)).filter((row) => {
      const box = row.querySelector("input[type=checkbox]")
      return box && box.checked && !box.disabled
    })
  }

  cents(rows) {
    return rows.reduce((sum, row) => sum + Number(row.dataset.cents), 0)
  }

  format(cents) {
    const value = (cents / 100).toFixed(2).replace(".", ",")
    return `R$ ${value.replace(/\B(?=(\d{3})+(?!\d))/g, ".")}`
  }

  equalSums() {
    const pays = this.checkedRows('[data-row="payment"]')
    const docs = this.checkedRows('[data-row="pool-document"]')
    return pays.length > 0 && docs.length > 0 && this.cents(pays) === this.cents(docs)
  }

  clearChecks() {
    this.element.querySelectorAll('input[type="checkbox"]').forEach((box) => { box.checked = false })
  }

  checkPayment(id) {
    const box = this.element.querySelector(`[data-row="payment"][data-payment-id="${id}"] input[type="checkbox"]`)
    if (box) box.checked = true
  }

  checkDocument(id) {
    const box = this.element.querySelector(`[data-row="pool-document"][data-document-id="${id}"] input[type="checkbox"]`)
    if (box) box.checked = true
  }
}
