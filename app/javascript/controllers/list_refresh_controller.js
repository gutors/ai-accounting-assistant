import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  rememberFormFocus({ target }) {
    if (target === this.element) this.formFocus = null
    if (target.tagName === "FORM" && target.dataset.turboFrame === this.element.id) {
      this.formFocus = document.activeElement
    }
  }

  preserve(event) {
    if (event.target !== this.element) return

    this.pendingFrameVisit = this.element.src
    const render = event.detail.render
    event.detail.render = (currentFrame, newFrame) => {
      const { scrollX, scrollY } = window
      const active = document.activeElement
      const focused = active === document.body ? this.formFocus : active
      this.formFocus = null

      for (const fold of currentFrame.querySelectorAll("details[id]")) {
        const replacement = this.findById(newFrame, fold.id)
        if (replacement) replacement.open = fold.open
      }

      render(currentFrame, newFrame)

      if (focused && !focused.isConnected) {
        const focusTarget = this.findById(currentFrame, focused.id) ||
          this.findById(currentFrame, focused.dataset.listRefreshFocusFallback)
        focusTarget?.focus({ preventScroll: true })
      }
      window.scrollTo({ left: scrollX, top: scrollY, behavior: "instant" })
    }
  }

  checkHistory(event) {
    const { url } = event.detail
    if (url !== this.pendingFrameVisit) return

    this.pendingFrameVisit = null
    // Turbo promotes the frame after rendering. Back may have already restored a different URL.
    if (url !== window.location.href) event.preventDefault()
  }

  follow(event) {
    if (event.target !== this.element) return

    event.preventDefault()
    event.detail.visit(event.detail.response.url)
  }

  findById(frame, id) {
    return id ? frame.querySelector(`#${CSS.escape(id)}`) : null
  }
}
