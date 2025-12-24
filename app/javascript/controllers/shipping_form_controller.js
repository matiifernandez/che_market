import { Controller } from "@hotwired/stimulus"

// Handles shipping form validation with warnings
export default class extends Controller {
  static targets = ["form", "status", "trackingNumber", "carrier", "warningModal"]

  connect() {
    this.skipValidation = false
    this.boundHandleSubmit = this.handleSubmit.bind(this)
    this.formTarget.addEventListener("submit", this.boundHandleSubmit)
  }

  disconnect() {
    this.formTarget?.removeEventListener("submit", this.boundHandleSubmit)
  }

  handleSubmit(event) {
    if (this.skipValidation) {
      this.skipValidation = false
      return
    }

    const status = this.statusTarget.value
    const trackingNumber = this.trackingNumberTarget.value.trim()

    // Only warn when changing to shipped without tracking info
    if (status === "shipped" && !trackingNumber) {
      event.preventDefault()
      this.showWarning()
    }
  }

  showWarning() {
    this.warningModalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  hideWarning() {
    this.warningModalTarget.classList.add("hidden")
    document.body.style.overflow = ""
  }

  continueWithoutTracking() {
    this.hideWarning()
    this.skipValidation = true
    this.formTarget.requestSubmit()
  }

  goBack() {
    this.hideWarning()
    // Focus on tracking number field
    this.trackingNumberTarget.focus()
  }
}
