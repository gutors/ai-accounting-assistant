import { Controller } from "@hotwired/stimulus"

const DELAY_MS = 1000

export default class extends Controller {
  static targets = [ "panel", "copy" ]

  connect() {
    this.pending = 0
    this.timer = null
    this.nextCopy = ""
    this.onSubmitStart = this.submitStart.bind(this)
    this.onBeforeFetch = this.beforeFetch.bind(this)
    this.onAfterFetch = this.afterFetch.bind(this)
    this.onWaitStart = this.externalStart.bind(this)
    this.onWaitEnd = this.externalEnd.bind(this)
    document.addEventListener("turbo:submit-start", this.onSubmitStart)
    document.addEventListener("turbo:before-fetch-request", this.onBeforeFetch)
    document.addEventListener("turbo:before-fetch-response", this.onAfterFetch)
    document.addEventListener("turbo:fetch-request-error", this.onAfterFetch)
    document.addEventListener("wait:start", this.onWaitStart)
    document.addEventListener("wait:end", this.onWaitEnd)
  }

  disconnect() {
    document.removeEventListener("turbo:submit-start", this.onSubmitStart)
    document.removeEventListener("turbo:before-fetch-request", this.onBeforeFetch)
    document.removeEventListener("turbo:before-fetch-response", this.onAfterFetch)
    document.removeEventListener("turbo:fetch-request-error", this.onAfterFetch)
    document.removeEventListener("wait:start", this.onWaitStart)
    document.removeEventListener("wait:end", this.onWaitEnd)
    this.clearTimer()
    this.pending = 0
    this.hide()
  }

  submitStart(event) {
    const form = event.target
    if (form && form.dataset.waitCopy) this.nextCopy = form.dataset.waitCopy
  }

  beforeFetch(event) {
    if (this.prefetch(event)) return
    const copy = this.nextCopy
    this.nextCopy = ""
    this.begin(copy)
  }

  afterFetch() {
    this.end()
  }

  externalStart(event) {
    this.begin(event.detail && event.detail.copy ? event.detail.copy : "")
  }

  externalEnd() {
    this.end()
  }

  begin(copy) {
    this.pending += 1
    if (copy) {
      this.clearTimer()
      this.show(copy)
      return
    }
    if (this.element.classList.contains("is-waiting") || this.timer) return
    this.timer = window.setTimeout(() => {
      this.timer = null
      if (this.pending > 0) this.show("")
    }, DELAY_MS)
  }

  end() {
    this.pending = Math.max(0, this.pending - 1)
    if (this.pending > 0) return
    this.clearTimer()
    this.hide()
  }

  show(copy) {
    this.element.classList.add("is-waiting")
    if (copy) {
      this.element.classList.add("is-waiting-copy")
      this.copyTarget.textContent = copy
    } else {
      this.element.classList.remove("is-waiting-copy")
      this.copyTarget.textContent = "Aguarde"
    }
    this.panelTarget.hidden = false
    this.panelTarget.removeAttribute("inert")
    this.panelTarget.removeAttribute("aria-hidden")
    this.panelTarget.setAttribute("aria-busy", "true")
  }

  hide() {
    this.element.classList.remove("is-waiting", "is-waiting-copy")
    this.copyTarget.textContent = "Aguarde"
    this.panelTarget.hidden = true
    this.panelTarget.setAttribute("inert", "")
    this.panelTarget.setAttribute("aria-hidden", "true")
    this.panelTarget.setAttribute("aria-busy", "false")
  }

  clearTimer() {
    if (!this.timer) return
    window.clearTimeout(this.timer)
    this.timer = null
  }

  prefetch(event) {
    const headers = event.detail && event.detail.fetchOptions && event.detail.fetchOptions.headers
    if (!headers) return false
    return headers["X-Sec-Purpose"] === "prefetch" || headers["Purpose"] === "prefetch"
  }
}
