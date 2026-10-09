import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.value = this.format(this.digits(this.element.value))
  }

  typed() {
    this.element.value = this.format(this.digits(this.element.value))
  }

  digits(value) {
    return String(value).replace(/\D/g, "").slice(0, 14)
  }

  format(digits) {
    if (digits.length === 0) return ""

    if (digits.length <= 11) {
      const a = digits.slice(0, 3)
      const b = digits.slice(3, 6)
      const c = digits.slice(6, 9)
      const d = digits.slice(9, 11)
      let out = a
      if (digits.length > 3) out += `.${b}`
      if (digits.length > 6) out += `.${c}`
      if (digits.length > 9) out += `-${d}`
      return out
    }

    const a = digits.slice(0, 2)
    const b = digits.slice(2, 5)
    const c = digits.slice(5, 8)
    const d = digits.slice(8, 12)
    const e = digits.slice(12, 14)
    let out = `${a}.${b}.${c}/${d}`
    if (digits.length > 12) out += `-${e}`
    return out
  }
}
