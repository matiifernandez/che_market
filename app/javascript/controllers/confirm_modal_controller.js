import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="confirm-modal"
export default class extends Controller {
  static targets = ["modal", "title", "message", "form", "methodField", "submitButton"]
  static values = {
    title: String,
    message: String,
    url: String
  }

  open(event) {
    event.preventDefault()

    // Get values from the clicked button if available
    const button = event.currentTarget
    const title = button.dataset.confirmModalTitleParam || this.titleValue || "Confirmar acción"
    const message = button.dataset.confirmModalMessageParam || this.messageValue || "¿Estás seguro de que deseas continuar?"
    const url = button.dataset.confirmModalUrlParam || this.urlValue
    const method = button.dataset.confirmModalMethodParam || "delete"
    const buttonText = button.dataset.confirmModalButtonParam || "Eliminar"

    // Update modal content
    if (this.hasTitleTarget) {
      this.titleTarget.textContent = title
    }
    if (this.hasMessageTarget) {
      this.messageTarget.textContent = message
    }
    if (this.hasFormTarget && url) {
      this.formTarget.action = url
    }
    if (this.hasMethodFieldTarget) {
      this.methodFieldTarget.value = method
    }
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.textContent = buttonText
    }

    // Show modal
    this.modalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")

    // Focus trap - focus first focusable element
    requestAnimationFrame(() => {
      const focusable = this.modalTarget.querySelector("button, [href], input, select, textarea")
      if (focusable) focusable.focus()
    })
  }

  close(event) {
    if (event) event.preventDefault()
    this.modalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  closeOnBackdrop(event) {
    if (event.target === this.modalTarget) {
      this.close()
    }
  }
}
