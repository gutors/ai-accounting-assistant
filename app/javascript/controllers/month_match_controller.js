import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "form", "sumPayments", "sumDocuments", "verdict", "paymentList", "documentList", "emptyDocuments", "documentToggle", "paymentToggle", "documentTotal", "exceptionNotice", "baseKind", "extraKind", "submit", "exceptionButton", "cancelException" ]

  connect() {
    this.showPayments = false
    this.showDocuments = false
    this.recompute()
  }

  toggle(event) {
    if (this.hasCancelExceptionTarget && !this.cancelExceptionTarget.hidden && event.target.closest('[data-current="true"]')) {
      event.target.checked = true
    }
    this.recompute()
  }
  togglePayments() { this.showPayments = !this.showPayments; this.recompute() }
  toggleDocuments() { this.showDocuments = !this.showDocuments; this.recompute() }

  chooseException(event) {
    const option = event.currentTarget
    option.parentElement.querySelectorAll('[role="option"]').forEach((item) => item.removeAttribute("aria-current"))
    option.setAttribute("aria-current", "true")
    this.documentListTarget.querySelectorAll('input[type="checkbox"]').forEach((input) => { input.checked = false })
    this.paymentListTarget.querySelectorAll('[data-row="payment"]').forEach((row) => {
      row.querySelector('input[type="checkbox"]').checked = row.dataset.current === "true"
    })
    this.baseKindTarget.value = option.dataset.kind || ""
    this.baseKindTarget.disabled = !option.dataset.kind
    this.extraKindTarget.value = option.dataset.extraId || ""
    this.extraKindTarget.disabled = !option.dataset.extraId
    this.formTarget.action = this.formTarget.dataset.exceptionUrl
    this.submitTarget.value = "Marcar exceção"
    this.exceptionButtonTarget.textContent = option.textContent.trim()
    this.cancelExceptionTarget.hidden = false
    this.exceptionNoticeTarget.hidden = false
    this.documentListTarget.hidden = true
    this.documentToggleTarget.hidden = true
    this.documentTotalTarget.hidden = true
    if (this.hasPaymentToggleTarget) this.paymentToggleTarget.hidden = true
    this.showPayments = false
    this.recompute()
  }

  cancelException() {
    this.exceptionButtonTarget.parentElement.querySelectorAll('[role="option"]').forEach((item) => item.removeAttribute("aria-current"))
    this.baseKindTarget.disabled = true
    this.extraKindTarget.disabled = true
    this.formTarget.action = this.formTarget.dataset.matchUrl
    this.submitTarget.value = "Confirmar casamento"
    this.exceptionButtonTarget.textContent = "Escolher exceção"
    this.cancelExceptionTarget.hidden = true
    this.exceptionNoticeTarget.hidden = true
    this.documentListTarget.hidden = false
    this.documentToggleTarget.hidden = false
    this.documentTotalTarget.hidden = false
    if (this.hasPaymentToggleTarget) this.paymentToggleTarget.hidden = false
    this.recompute()
  }

  recompute() {
    const pays = this.rows(this.paymentListTarget)
    const docs = this.rows(this.documentListTarget)
    const payCents = this.cents(pays)
    const docCents = this.cents(docs)
    this.sumPaymentsTarget.textContent = this.format(payCents)
    this.sumDocumentsTarget.textContent = this.format(docCents)
    this.verdictTarget.textContent = (this.hasCancelExceptionTarget && !this.cancelExceptionTarget.hidden) ? "" : !pays.length || !docs.length ? "" : docCents < payCents ? "Documentos somam menos" : docCents === payCents ? "Soma igual" : "Documentos somam mais"
    this.paymentListTarget.querySelectorAll('[data-row="payment"]').forEach((row) => { row.hidden = !row.querySelector('input').checked && !this.showPayments })
    this.documentListTarget.querySelectorAll('[data-row="pool-document"]').forEach((row) => { row.hidden = !row.querySelector('input').checked && !this.showDocuments })
    this.emptyDocumentsTarget.hidden = docs.length > 0 || (this.hasCancelExceptionTarget && !this.cancelExceptionTarget.hidden)
    if (this.hasPaymentToggleTarget) this.paymentToggleTarget.textContent = this.showPayments ? "Concluir seleção de pagamentos" : "Adicionar outro pagamento"
    this.documentToggleTarget.textContent = this.showDocuments ? "Concluir seleção de documentos" : "Adicionar documentos"
  }

  rows(container) { return Array.from(container.querySelectorAll('[data-row]')).filter((row) => row.querySelector('input:checked')) }
  cents(rows) { return rows.reduce((sum, row) => sum + Number(row.dataset.cents), 0) }
  format(cents) { return `R$ ${(cents / 100).toFixed(2).replace(".", ",").replace(/\B(?=(\d{3})+(?!\d))/g, ".")}` }
}
