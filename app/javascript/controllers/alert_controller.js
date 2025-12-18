import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="alert"
export default class extends Controller {
  static values = {
    dismissAfter: { type: Number, default: 5000 }
  }

  connect() {
    // Trigger enter animation
    requestAnimationFrame(() => {
      this.element.classList.add("alert-enter")
    })

    // Auto-dismiss after specified time
    if (this.dismissAfterValue > 0) {
      this.timeout = setTimeout(() => {
        this.dismiss()
      }, this.dismissAfterValue)
    }
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  dismiss() {
    // Clear timeout if manually dismissed
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Trigger exit animation
    this.element.classList.remove("alert-enter")
    this.element.classList.add("alert-exit")

    // Remove element after animation completes
    this.element.addEventListener("animationend", () => {
      this.element.remove()
    }, { once: true })
  }
}
