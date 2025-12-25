import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "form"]

  show(event) {
    event.preventDefault()
    this.modalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.modalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  proceed() {
    this.formTarget.requestSubmit()
  }

  // Close on escape key
  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  // Close on background click
  closeOnBackground(event) {
    if (event.target === this.modalTarget) {
      this.close()
    }
  }
}
