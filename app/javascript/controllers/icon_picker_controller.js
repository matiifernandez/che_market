import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="icon-picker"
export default class extends Controller {
  static targets = ["input", "option"]
  static values = { selected: String }

  connect() {
    this.updateSelection()
  }

  select(event) {
    const icon = event.currentTarget.dataset.icon
    this.selectedValue = icon
    this.inputTarget.value = icon
    this.updateSelection()
  }

  updateSelection() {
    this.optionTargets.forEach(option => {
      const isSelected = option.dataset.icon === this.selectedValue

      if (isSelected) {
        option.classList.remove("border-gray-200", "hover:border-gray-300", "hover:bg-gray-50")
        option.classList.add("border-indigo-500", "bg-indigo-50", "ring-2", "ring-indigo-500")
      } else {
        option.classList.remove("border-indigo-500", "bg-indigo-50", "ring-2", "ring-indigo-500")
        option.classList.add("border-gray-200", "hover:border-gray-300", "hover:bg-gray-50")
      }
    })
  }

  selectedValueChanged() {
    this.updateSelection()
  }
}
