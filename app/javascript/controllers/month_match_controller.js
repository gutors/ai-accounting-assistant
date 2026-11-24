import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "selectedPayments", "selectedDocuments", "form", "sumPayments", "sumDocuments", "verdict", "paymentList", "documentList", "emptyDocuments", "documentToggle", "paymentToggle", "documentTotal", "exceptionNotice", "baseKind", "extraKind", "submit", "exceptionButton", "cancelException", "paymentToggleLabel", "documentToggleLabel", "difference", "differenceAmount", "required", "observationDetails", "error", "exceptionLabel" ]

  connect() {
    if (!this.hasFormTarget) return
    this.showPayments = false
    this.showDocuments = false
    if (this.hasPaymentToggleTarget) this.paymentToggleTarget.after(this.paymentListTarget)
    this.documentToggleTarget.after(this.documentListTarget)
    this.recompute()
  }

  remove(event) {
    const input = this.element.querySelector(`input[name="${event.currentTarget.dataset.name}"][value="${event.currentTarget.dataset.id}"]`)
    if (!input || (this.hasCancelExceptionTarget && !this.cancelExceptionTarget.hidden)) return
    input.checked = false
    this.errorTarget.hidden = true
    this.recompute()
  }

  toggle(event) {
    if (this.hasCancelExceptionTarget && !this.cancelExceptionTarget.hidden && event.target.closest('[data-current="true"]')) {
      event.target.checked = true
    }
    this.errorTarget.hidden = true
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
    this.submitTarget.textContent = "Marcar exceção"
    this.exceptionLabelTarget.textContent = option.textContent.trim()
    this.cancelExceptionTarget.hidden = false
    this.exceptionNoticeTarget.hidden = false
    this.documentListTarget.hidden = true
    this.documentToggleTarget.hidden = true
    this.documentTotalTarget.hidden = true
    this.differenceTarget.hidden = true
    this.observationDetailsTarget.hidden = true
    if (this.hasPaymentToggleTarget) this.paymentToggleTarget.hidden = true
    this.showPayments = false
    this.recompute()
  }

  cancelException() {
    this.exceptionButtonTarget.parentElement.querySelectorAll('[role="option"]').forEach((item) => item.removeAttribute("aria-current"))
    this.baseKindTarget.disabled = true
    this.extraKindTarget.disabled = true
    this.formTarget.action = this.formTarget.dataset.matchUrl
    this.submitTarget.textContent = "Confirmar casamento"
    this.exceptionLabelTarget.textContent = "Escolher exceção"
    this.cancelExceptionTarget.hidden = true
    this.exceptionNoticeTarget.hidden = true
    this.documentListTarget.hidden = false
    this.documentToggleTarget.hidden = false
    this.documentTotalTarget.hidden = false
    this.differenceTarget.hidden = false
    this.observationDetailsTarget.hidden = false
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
    const comparable = pays.length > 0 && docs.length > 0
    const delta = docCents - payCents
    this.differenceTarget.dataset.tone = !comparable ? "pending" : delta < 0n ? "less" : delta > 0n ? "more" : "equal"
    this.differenceAmountTarget.textContent = !comparable ? "—" : (delta < 0n ? "− " : delta > 0n ? "+ " : "") + this.format((delta < 0n ? -delta : delta))
    this.verdictTarget.textContent = !comparable ? "Aguardando seleção" : delta < 0n ? "Documentos somam menos" : delta > 0n ? "Documentos somam mais" : "Valores conferem"
    this.requiredTarget.hidden = !comparable || delta >= 0n
    this.observationDetailsTarget.querySelector("textarea").setAttribute("aria-required", String(comparable && delta < 0n))
    this.renderSelected(this.selectedPaymentsTarget, pays)
    this.renderSelected(this.selectedDocumentsTarget, docs)
    this.paymentListTarget.hidden = !this.showPayments
    this.documentListTarget.hidden = !this.showDocuments || (this.hasCancelExceptionTarget && !this.cancelExceptionTarget.hidden)
    this.selectedDocumentsTarget.hidden = this.hasCancelExceptionTarget && !this.cancelExceptionTarget.hidden
    this.emptyDocumentsTarget.hidden = docs.length > 0 || (this.hasCancelExceptionTarget && !this.cancelExceptionTarget.hidden)
    if (this.hasPaymentToggleTarget) {
      this.paymentToggleLabelTarget.textContent = this.showPayments ? "Fechar lista" : "Adicionar pagamento"
      this.paymentToggleTarget.setAttribute("aria-expanded", String(this.showPayments))
    }
    this.documentToggleLabelTarget.textContent = this.showDocuments ? "Fechar lista" : "Adicionar documento"
    this.documentToggleTarget.setAttribute("aria-expanded", String(this.showDocuments))
  }

  validate(event) {
    if (!this.baseKindTarget.disabled || !this.extraKindTarget.disabled) return
    const pays = this.rows(this.paymentListTarget)
    const docs = this.rows(this.documentListTarget)
    if (pays.length && docs.length && this.cents(docs) < this.cents(pays) && !this.observationDetailsTarget.querySelector("textarea").value.trim()) {
      event.preventDefault()
      this.errorTarget.textContent = "Informe a observação do casamento"
      this.errorTarget.hidden = false
      this.observationDetailsTarget.open = true
      this.errorTarget.focus()
    }
  }

  renderSelected(container, rows) {
    container.replaceChildren(...rows.map((row) => {
      const selected = document.createElement("div")
      selected.className = "match-picker-row match-selected-row"
      if (row.dataset.current) selected.dataset.current = row.dataset.current
      if (row.dataset.paymentId) selected.dataset.paymentId = row.dataset.paymentId
      selected.append(row.querySelector(".match-row-content").cloneNode(true))
      const input = row.querySelector("input")
      const remove = document.createElement("button")
      remove.type = "button"
      remove.className = "match-remove"
      remove.dataset.action = "month-match#remove"
      remove.dataset.name = input.name
      remove.dataset.id = input.value
      remove.setAttribute("aria-label", `Retirar ${row.querySelector(".match-name").textContent} da seleção`)
      remove.innerHTML = '<svg aria-hidden="true" viewBox="0 0 16 16"><path d="M4 4l8 8M12 4l-8 8" /></svg>'
      if (!(this.hasCancelExceptionTarget && !this.cancelExceptionTarget.hidden)) selected.append(remove)
      return selected
    }))
  }

  rows(container) { return Array.from(container.querySelectorAll('[data-row]')).filter((row) => row.querySelector('input:checked')) }
  cents(rows) { return rows.reduce((sum, row) => sum + BigInt(row.dataset.cents), 0n) }
  format(cents) {
    const reais = (cents / 100n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".")
    const fraction = (cents % 100n).toString().padStart(2, "0")
    return `R$ ${reais},${fraction}`
  }
}
