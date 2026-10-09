import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.value = this.formatCents(this.parseReais(this.element.value))
  }

  typed() {
    const digits = this.element.value.replace(/\D/g, "")
    this.element.value = this.formatCents(Number(digits || 0))
  }

  parseReais(value) {
    const s = String(value).trim().replace(/[\s\u00a0]/g, "").replace("R$", "")
    if (s === "") return 0

    const negative = s.startsWith("-")
    const unsigned = s.replace(/^-/, "")
    let cents
    if (unsigned.includes(",")) {
      const [ whole, frac = "" ] = unsigned.split(",", 2)
      cents = Number(whole.replace(/\./g, "") || 0) * 100 + this.fracToCents(frac)
    } else if (unsigned.includes(".")) {
      const [ whole, frac = "" ] = unsigned.split(".", 2)
      cents = Number(whole || 0) * 100 + this.fracToCents(frac)
    } else {
      cents = Number(unsigned || 0) * 100
    }
    return Math.abs(negative ? -cents : cents)
  }

  fracToCents(frac) {
    const digits = String(frac).replace(/\D/g, "")
    if (digits === "") return 0

    const padded = digits.padEnd(3, "0")
    const major = Number(padded.slice(0, 2))
    return Number(padded[2]) >= 5 ? major + 1 : major
  }

  formatCents(cents) {
    const n = Math.abs(Math.trunc(Number(cents) || 0))
    const whole = Math.floor(n / 100)
    const frac = n % 100
    const grouped = String(whole).replace(/(\d)(?=(\d{3})+(?!\d))/g, "$1.")
    return `${grouped},${String(frac).padStart(2, "0")}`
  }
}
