import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "wait", "fields", "drop", "preview", "input", "submit", "thumb", "thumbWrap", "proofFile" ]

  pick() {
    this.inputTarget.click()
  }

  identify() {
    const file = this.inputTarget.files && this.inputTarget.files[0]
    if (!file) return

    this.pendingFile = file
    this.paintProof(file)
    this.waitTarget.hidden = false
    this.waitTarget.classList.remove("hidden")
    this.waitTarget.textContent = "Identificando o arquivo…"
    if (this.hasFieldsTarget) {
      this.fieldsTarget.hidden = true
      this.fieldsTarget.classList.add("hidden")
    }

    const data = new FormData()
    data.append("file", file)
    const csrf = document.querySelector('meta[name="csrf-token"]')
    if (csrf) data.append("authenticity_token", csrf.content)

    fetch("/supporting_documents/identify", {
      method: "POST",
      body: data,
      headers: { Accept: "text/vnd.turbo-stream.html" },
      credentials: "same-origin"
    }).then(async (response) => {
      const body = await response.text()
      if (window.Turbo) window.Turbo.renderStreamMessage(body)
      this.paintProofAfterStream(file)
      if (!response.ok) {
        this.resetWaitPrompt()
      }
    }).catch(() => {
      this.resetWaitPrompt()
    })
  }

  resetWaitPrompt() {
    this.waitTarget.textContent = "Inclua o documento. Valor, data e favorecido saem do arquivo."
  }

  clear() {
    this.pendingFile = null
    this.revokeThumb()
    this.inputTarget.value = ""
    const wait = this.element.querySelector("[data-document-identify-target='wait']")
    const fields = this.element.querySelector("[data-document-identify-target='fields']")
    const drop = this.element.querySelector("[data-document-identify-target='drop']")
    const preview = this.element.querySelector("[data-document-identify-target='preview']")
    if (wait) {
      wait.hidden = false
      wait.classList.remove("hidden")
      this.resetWaitPrompt()
    }
    if (fields) {
      fields.hidden = true
      fields.classList.add("hidden")
    }
    if (drop) {
      drop.hidden = false
      drop.classList.remove("hidden")
    }
    if (preview) {
      preview.hidden = true
      preview.classList.add("hidden")
    }
  }

  typed() {
    if (!this.hasSubmitTarget) return
    const amount = this.element.querySelector("#amount")
    const date = this.element.querySelector("#date")
    const payee = this.element.querySelector("#payee")
    this.submitTarget.disabled = !(amount && amount.value && date && date.value && payee && payee.value)
  }

  paintProofAfterStream(file) {
    this.paintProof(file)
    requestAnimationFrame(() => this.paintProof(file))
    document.addEventListener("turbo:after-stream-render", () => this.paintProof(file), { once: true })
  }

  paintProof(file) {
    if (!file) return

    const drop = this.element.querySelector("[data-document-identify-target='drop']")
    const preview = this.element.querySelector("[data-document-identify-target='preview']")
    const proofFile = this.element.querySelector("[data-document-identify-target='proofFile']")
    const thumb = this.element.querySelector("[data-document-identify-target='thumb']")
    const thumbWrap = this.element.querySelector("[data-document-identify-target='thumbWrap']")

    if (drop) {
      drop.hidden = true
      drop.classList.add("hidden")
    }
    if (preview) {
      preview.hidden = false
      preview.classList.remove("hidden")
    }
    if (proofFile && !proofFile.textContent.trim()) {
      const kind = file.name.toLowerCase().endsWith(".xml") ? "XML" : "Foto"
      proofFile.textContent = `${kind} · ${file.name}`
    }
    if (!this.imageFile(file) || !thumb) return

    if (!this.thumbUrl) this.thumbUrl = URL.createObjectURL(file)
    thumb.src = this.thumbUrl
    thumb.alt = file.name
    thumb.hidden = false
    thumb.classList.remove("hidden")
    if (thumbWrap) {
      thumbWrap.hidden = false
      thumbWrap.classList.remove("hidden")
    }
  }

  imageFile(file) {
    return file.type.startsWith("image/") || /\.(jpe?g|png|webp)$/i.test(file.name)
  }

  revokeThumb() {
    if (this.thumbUrl) {
      URL.revokeObjectURL(this.thumbUrl)
      this.thumbUrl = null
    }
  }
}
