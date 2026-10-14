import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "sumPayments", "sumDocuments", "verdict" ]

  connect() {
    this.recompute()
  }

  toggle() {
    this.recompute()
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
}
