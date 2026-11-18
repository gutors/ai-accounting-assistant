import { Controller } from "@hotwired/stimulus"

const MIN = 1
const MAX = 4
const STEP = 0.25

export default class extends Controller {
  static targets = [ "image", "pane", "controls", "inButton", "outButton" ]
  static values = { scale: { type: Number, default: MIN } }

  connect() {
    this.scaleValue = MIN
    this.lastSrc = this.hasImageTarget ? this.imageTarget.getAttribute("src") : null
    this.onWheel = (event) => this.wheel(event)
    this.onPointerMove = (event) => this.pointerMove(event)
    this.onPointerUp = () => this.pointerUp()
    if (this.hasPaneTarget) this.paneTarget.addEventListener("wheel", this.onWheel, { passive: false })
    this.observeImage()
    this.sync()
  }

  disconnect() {
    this.observer?.disconnect()
    if (this.hasPaneTarget) this.paneTarget.removeEventListener("wheel", this.onWheel)
    this.pointerUp()
  }

  in() {
    this.setScale(this.scaleValue + STEP)
  }

  out() {
    this.setScale(this.scaleValue - STEP)
  }

  pointerDown(event) {
    if (event.button) return
    if (!this.imageShown() || this.scaleValue <= MIN) return
    event.preventDefault()
    this.drag = {
      x: event.clientX,
      y: event.clientY,
      sl: this.paneTarget.scrollLeft,
      st: this.paneTarget.scrollTop
    }
    window.addEventListener("pointermove", this.onPointerMove)
    window.addEventListener("pointerup", this.onPointerUp)
    window.addEventListener("pointercancel", this.onPointerUp)
  }

  pointerMove(event) {
    if (!this.drag) return
    event.preventDefault()
    this.paneTarget.scrollLeft = this.drag.sl - (event.clientX - this.drag.x)
    this.paneTarget.scrollTop = this.drag.st - (event.clientY - this.drag.y)
  }

  pointerUp() {
    this.drag = null
    window.removeEventListener("pointermove", this.onPointerMove)
    window.removeEventListener("pointerup", this.onPointerUp)
    window.removeEventListener("pointercancel", this.onPointerUp)
  }

  wheel(event) {
    if (!this.imageShown()) return
    event.preventDefault()
    if (event.deltaY < 0) this.setScale(this.scaleValue + STEP)
    else if (event.deltaY > 0) this.setScale(this.scaleValue - STEP)
  }

  setScale(next) {
    const clamped = Math.min(MAX, Math.max(MIN, Math.round(next / STEP) * STEP))
    this.scaleValue = Number(clamped.toFixed(2))
    this.sync()
  }

  imageShown() {
    if (!this.hasImageTarget) return false
    const img = this.imageTarget
    if (img.hidden || img.classList.contains("hidden")) return false
    return !!img.getAttribute("src")
  }

  observeImage() {
    if (!this.hasImageTarget) return
    this.observer = new MutationObserver(() => {
      const src = this.imageTarget.getAttribute("src")
      if (src !== this.lastSrc) {
        this.lastSrc = src
        this.scaleValue = MIN
        if (this.hasPaneTarget) {
          this.paneTarget.scrollLeft = 0
          this.paneTarget.scrollTop = 0
        }
      }
      this.sync()
    })
    this.observer.observe(this.imageTarget, { attributes: true, attributeFilter: [ "src", "hidden", "class" ] })
  }

  sync() {
    const shown = this.imageShown()
    if (this.hasControlsTarget) this.controlsTarget.hidden = !shown
    if (this.hasInButtonTarget) this.inButtonTarget.disabled = !shown || this.scaleValue >= MAX
    if (this.hasOutButtonTarget) this.outButtonTarget.disabled = !shown || this.scaleValue <= MIN
    if (!this.hasImageTarget) return
    const img = this.imageTarget
    if (!shown || this.scaleValue === MIN) {
      img.style.width = ""
      img.style.height = ""
      img.style.maxWidth = ""
      img.style.maxHeight = ""
      img.style.cursor = ""
      return
    }
    const pct = `${this.scaleValue * 100}%`
    img.style.width = pct
    img.style.height = pct
    img.style.maxWidth = "none"
    img.style.maxHeight = "none"
    img.style.cursor = "grab"
  }
}
