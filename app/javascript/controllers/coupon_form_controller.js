import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="coupon-form"
export default class extends Controller {
  static targets = ["discountType", "percentage", "amount"]

  connect() {
    this.sync()
  }

  sync() {
    if (!this.hasDiscountTypeTarget) return

    const type = this.discountTypeTarget.value
    const isPercentage = type === "percentage"

    if (this.hasPercentageTarget) {
      this.percentageTarget.disabled = !isPercentage
      if (!isPercentage) this.percentageTarget.value = ""
    }

    if (this.hasAmountTarget) {
      this.amountTarget.disabled = isPercentage
      if (isPercentage) this.amountTarget.value = ""
    }
  }
}
