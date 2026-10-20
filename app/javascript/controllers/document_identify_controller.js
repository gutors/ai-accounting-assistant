import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "wait", "fields", "drop", "preview", "input", "submit", "thumb", "thumbWrap", "proofFile", "pdfThumb" ]

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

    document.dispatchEvent(new CustomEvent("wait:start", { detail: { copy: "Identificando o arquivo…" } }))
    fetch("/supporting_documents/identify", {
      method: "POST",
      body: data,
      headers: { Accept: "text/vnd.turbo-stream.html" },
      credentials: "same-origin"
    }).then(async (response) => {
      const body = await response.text()
      if (this.pendingFile !== file) return
      this.renderIdentifyStream(body, file)
      if (!response.ok) {
        this.resetWaitPrompt()
      }
    }).catch(() => {
      this.resetWaitPrompt()
    }).finally(() => {
      document.dispatchEvent(new CustomEvent("wait:end"))
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

  renderIdentifyStream(body, file) {
    if (!window.Turbo) {
      this.paintProof(file)
      return
    }

    const onBeforeStream = (event) => {
      const original = event.detail.render
      event.detail.render = async (streamElement) => {
        await original(streamElement)
        if (this.pendingFile !== file) return
        this.paintProof(file)
      }
    }

    document.addEventListener("turbo:before-stream-render", onBeforeStream)
    window.Turbo.renderStreamMessage(body)
    document.removeEventListener("turbo:before-stream-render", onBeforeStream)
  }

  paintProof(file) {
    if (!file) return

    const drop = this.element.querySelector("[data-document-identify-target='drop']")
    const preview = this.element.querySelector("[data-document-identify-target='preview']")
    const proofFile = this.element.querySelector("[data-document-identify-target='proofFile']")
    const thumb = this.element.querySelector("[data-document-identify-target='thumb']")
    const pdfThumb = this.element.querySelector("[data-document-identify-target='pdfThumb']")
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
    const showImage = this.imageFile(file) && thumb
    const showPdf = this.pdfFile(file) && pdfThumb
    if (!showImage && !showPdf) return

    if (!this.thumbUrl) this.thumbUrl = URL.createObjectURL(file)
    if (showImage) {
      thumb.src = this.thumbUrl
      thumb.alt = file.name
      thumb.hidden = false
      thumb.classList.remove("hidden")
      if (pdfThumb) {
        pdfThumb.removeAttribute("src")
        pdfThumb.hidden = true
        pdfThumb.classList.add("hidden")
      }
    }
    if (showPdf) {
      pdfThumb.setAttribute("src", this.thumbUrl)
      pdfThumb.hidden = false
      pdfThumb.classList.remove("hidden")
      if (thumb) {
        thumb.removeAttribute("src")
        thumb.hidden = true
        thumb.classList.add("hidden")
      }
    }
    if (thumbWrap) {
      thumbWrap.hidden = false
      thumbWrap.classList.remove("hidden")
    }
  }

  imageFile(file) {
    return file.type.startsWith("image/") || /\.(jpe?g|png|webp)$/i.test(file.name)
  }

  pdfFile(file) {
    return file.type === "application/pdf" || /\.pdf$/i.test(file.name)
  }

  revokeThumb() {
    if (this.thumbUrl) {
      URL.revokeObjectURL(this.thumbUrl)
      this.thumbUrl = null
    }
  }
}
