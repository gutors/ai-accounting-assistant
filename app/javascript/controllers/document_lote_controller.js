import { Controller } from "@hotwired/stimulus"

const MAX = 30
const MAX_NOTICE = "No máximo 30 arquivos neste lote"
const XML_UNREADABLE = "O XML da nota fiscal não pôde ser lido"

export default class extends Controller {
  static targets = [
    "input", "drop", "editor", "proof", "proofMeta", "proofWho", "proofHint",
    "arquivo", "kind", "amount", "date", "payee", "observation",
    "amountOrigin", "dateOrigin", "payeeOrigin", "toolbar", "sheet", "pair"
  ]

  toolbarAction(event) {
    if (event.target.closest("[data-lote-ready]")) this.includeReady()
    else if (event.target.closest("[data-lote-one]")) this.includeOne()
    else if (event.target.closest("[data-lote-remove]")) this.removeSelected()
  }

  selectRow(event) {
    const row = event.target.closest("[data-lote-id]")
    if (!row) return
    this.selected = row.getAttribute("data-lote-id")
    this.paintBook()
    this.renderSheet()
  }

  connect() {
    this.items = []
    this.selected = null
    this.busy = false
    this.sending = new Set()
  }

  pick() {
    this.inputTarget.click()
  }

  add() {
    const incoming = Array.from(this.inputTarget.files || [])
    this.inputTarget.value = ""
    const room = MAX - this.items.length
    const accepted = incoming.slice(0, Math.max(room, 0))
    if (incoming.length > room) this.notice(MAX_NOTICE)
    accepted.forEach((file) => this.enqueue(file))
    this.render()
  }

  typed() {
    const item = this.selectedItem()
    if (!item || this.sending.has(item.id) || item.status === "error" || item.status === "identifying") return
    item.observation = this.observationTarget.value
    if (!item.locked) {
      item.amount = this.amountTarget.value
      item.date = this.dateTarget.value
      item.payee = this.payeeTarget.value
      item.status = this.ready(item) ? "pronto" : "digitar"
    }
    this.renderSheet()
    this.renderToolbar()
  }

  includeOne() {
    const item = this.selectedItem()
    if (!item || item.status !== "pronto" || this.busy) return
    this.beginSend([ item.id ])
    this.postOne(item).finally(() => this.endSend())
  }

  includeReady() {
    if (this.busy) return
    const ready = this.items.filter((item) => item.status === "pronto")
    if (!ready.length) return
    const data = this.formData()
    ready.forEach((item) => {
      data.append("documents[][file]", item.file, item.file.name)
      data.append("documents[][amount]", item.amount)
      data.append("documents[][date]", item.date)
      data.append("documents[][payee]", item.payee)
      if (item.observation) data.append("documents[][observation]", item.observation)
    })
    const sent = new Set(ready.map((item) => item.id))
    this.beginSend(sent)
    this.submit("/supporting_documents/batch", data).then((response) => {
      this.endSend()
      if (!response.ok) return
      this.items = this.items.filter((item) => !sent.has(item.id))
      this.selected = this.items[0] ? this.items[0].id : null
      this.render()
    })
  }

  beginSend(ids) {
    this.busy = true
    this.sending = new Set(ids)
    this.renderToolbar()
  }

  endSend() {
    this.busy = false
    this.sending = new Set()
    this.renderToolbar()
  }

  removeSelected() {
    const item = this.selectedItem()
    if (!item) return
    this.items = this.items.filter((row) => row.id !== item.id)
    this.selected = this.items[0] ? this.items[0].id : null
    this.render()
  }

  enqueue(file) {
    const item = {
      id: `${Date.now()}-${Math.random().toString(16).slice(2)}`,
      file,
      filename: file.name,
      status: "identifying",
      arquivo: file.name.toLowerCase().endsWith(".xml") ? "XML" : "Foto",
      kind: "",
      kindLabel: "",
      amount: "",
      date: "",
      payee: "",
      chave: "",
      observation: "",
      origin: "",
      locked: false,
      error: ""
    }
    this.items.push(item)
    this.selected = this.selected || item.id
    this.identify(item)
  }

  identify(item) {
    const data = this.formData()
    data.append("file", item.file, item.file.name)
    fetch("/supporting_documents/identify", {
      method: "POST",
      body: data,
      headers: { Accept: "text/vnd.turbo-stream.html" },
      credentials: "same-origin"
    }).then(async (response) => {
      const body = await response.text()
      if (!response.ok) {
        item.status = "error"
        item.error = this.noticeText(body) || XML_UNREADABLE
        if (window.Turbo) window.Turbo.renderStreamMessage(body)
      } else {
        this.applyIdentify(item, body)
      }
      this.render()
    })
  }

  applyIdentify(item, body) {
    const doc = this.streamDocument(body)
    const arquivo = doc.querySelector("#arquivo")
    const kind = doc.querySelector("select#kind")
    const amount = doc.querySelector("#amount")
    const date = doc.querySelector("#date")
    const payee = doc.querySelector("#payee")
    const chave = doc.querySelector("#chave")
    const origin = doc.querySelector('[data-origin="amount"]')
    item.arquivo = arquivo ? arquivo.value : item.arquivo
    item.kind = kind ? kind.value : ""
    item.kindLabel = item.kind === "recibo" ? "Recibo" : "Nota fiscal"
    item.amount = amount ? amount.value : ""
    item.date = date ? date.value : ""
    item.payee = payee ? payee.value : ""
    item.chave = chave ? chave.value : ""
    item.origin = origin ? origin.textContent.trim() : "Digitado"
    item.locked = !!(amount && amount.disabled)
    item.status = this.ready(item) ? "pronto" : "digitar"
  }

  postOne(item) {
    const data = this.formData()
    data.append("file", item.file, item.file.name)
    data.append("amount", item.amount)
    data.append("date", item.date)
    data.append("payee", item.payee)
    if (item.observation) data.append("observation", item.observation)
    return this.submit("/supporting_documents", data).then((response) => {
      if (!response.ok) return
      this.items = this.items.filter((row) => row.id !== item.id)
      this.selected = this.items[0] ? this.items[0].id : null
      this.render()
    })
  }

  submit(url, data) {
    return fetch(url, {
      method: "POST",
      body: data,
      headers: { Accept: "text/vnd.turbo-stream.html" },
      credentials: "same-origin"
    }).then(async (response) => {
      const body = await response.text()
      if (window.Turbo) window.Turbo.renderStreamMessage(body)
      return response
    })
  }

  render() {
    const empty = this.items.length === 0
    this.dropTarget.hidden = !empty
    this.editorTarget.hidden = empty
    if (empty) return
    this.paintBook()
    this.renderToolbar()
    this.renderSheet()
  }

  renderToolbar() {
    const ready = this.items.filter((item) => item.status === "pronto").length
    const off = this.busy ? " disabled" : ""
    this.toolbarTarget.innerHTML = `
      <button type="button" class="ds-btn-primary" data-lote-ready${off}>Incluir prontos (${ready})</button>
      <button type="button" class="ds-btn-secondary" data-lote-one${off}>Incluir este</button>
      <button type="button" class="ds-btn-secondary ds-btn-danger" data-lote-remove>Retirar</button>
    `
  }

  renderSheet() {
    const rows = this.items.map((item) => {
      const selected = item.id === this.selected
      const status = this.statusCopy(item)
      const payee = item.payee || item.filename
      const amount = item.amount ? `R$ ${item.amount}` : "—"
      const date = item.date ? this.formatDate(item.date) : "—"
      const error = item.status === "error" ? `<p class="text-meta text-margem">${this.escape(item.error)}</p>` : ""
      const identifying = item.status === "identifying" ? `<p class="text-meta">Identificando o arquivo…</p>` : ""
      return `
        <div role="option" data-lote-id="${item.id}" aria-selected="${selected ? "true" : "false"}" class="lote-row${selected ? " is-selected" : ""}${item.status === "error" ? " is-error" : ""}">
          <time class="tabular-nums">${date}</time>
          <div>
            <p class="font-medium">${this.escape(payee)}</p>
            <p class="text-meta text-ink-soft">${this.escape(item.arquivo)} · ${this.escape(item.filename)}</p>
            ${error}${identifying}
          </div>
          <p>${this.escape(item.kindLabel || (item.arquivo === "Foto" ? "Recibo" : "Nota fiscal"))}</p>
          <p class="tabular-nums font-medium text-right">${amount}</p>
          <p data-lote-status>${status}</p>
        </div>
      `
    }).join("")
    this.sheetTarget.innerHTML = `
      <div class="lote-sheet" role="listbox" aria-label="Lote">
        <div class="lote-head" aria-hidden="true">
          <span>Data</span>
          <span>Favorecido</span>
          <span>Tipo</span>
          <span class="text-right">Valor</span>
          <span>Situação</span>
        </div>
        ${rows}
      </div>
    `
  }

  paintBook() {
    const item = this.selectedItem()
    if (!item) return
    this.arquivoTarget.value = item.arquivo
    this.kindTarget.value = item.kind || (item.arquivo === "XML" ? "nota_fiscal" : "recibo")
    this.amountTarget.value = item.amount
    this.dateTarget.value = item.date
    this.payeeTarget.value = item.payee
    this.observationTarget.value = item.observation
    const origin = item.origin || "Digitado"
    this.amountOriginTarget.textContent = origin
    this.dateOriginTarget.textContent = origin
    this.payeeOriginTarget.textContent = origin
    const lock = item.locked
    this.amountTarget.disabled = lock
    this.dateTarget.disabled = lock
    this.payeeTarget.disabled = lock
    this.amountOriginTarget.classList.toggle("text-caixa", lock)
    this.dateOriginTarget.classList.toggle("text-caixa", lock)
    this.payeeOriginTarget.classList.toggle("text-caixa", lock)
    this.proofMetaTarget.textContent = `${item.arquivo} · ${item.filename}`
    this.proofWhoTarget.textContent = item.kindLabel || (item.kind === "recibo" ? "Recibo" : "")
    this.proofHintTarget.textContent = item.arquivo === "Foto" ? "Foto · sem leitura nesta versão" : item.arquivo
  }

  selectedItem() {
    return this.items.find((item) => item.id === this.selected)
  }

  ready(item) {
    return !!(item.amount && item.date && item.payee)
  }

  statusCopy(item) {
    if (item.status === "identifying") return "Identificando o arquivo…"
    if (item.status === "error") return "Erro"
    if (item.status === "pronto") return "Pronto"
    return "Digitar"
  }

  formatDate(iso) {
    const [year, month, day] = iso.split("-")
    if (!day) return iso
    return `${day}/${month}/${year}`
  }

  formData() {
    const data = new FormData()
    const csrf = document.querySelector('meta[name="csrf-token"]')
    if (csrf) data.append("authenticity_token", csrf.content)
    return data
  }

  notice(message) {
    const node = document.querySelector("[data-notice=error]")
    if (!node) return
    node.hidden = false
    node.textContent = message
  }

  noticeText(body) {
    const node = this.streamDocument(body).querySelector("[data-notice=error]")
    return node ? node.textContent.trim() : ""
  }

  streamDocument(body) {
    const wrap = document.createElement("div")
    wrap.innerHTML = body
    wrap.querySelectorAll("template").forEach((template) => {
      wrap.append(template.content.cloneNode(true))
    })
    return wrap
  }

  escape(value) {
    return String(value || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }
}
