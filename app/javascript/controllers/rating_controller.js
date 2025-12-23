import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["star", "input"]

  connect() {
    this.updateStars()
  }

  inputTargetConnected(input) {
    input.addEventListener('change', () => this.updateStars())
  }

  updateStars() {
    const checkedInput = this.inputTargets.find(input => input.checked)
    const rating = checkedInput ? parseInt(checkedInput.value) : 0

    this.starTargets.forEach((star, index) => {
      if (index < rating) {
        star.classList.remove('text-gray-300')
        star.classList.add('text-yellow-400')
      } else {
        star.classList.remove('text-yellow-400')
        star.classList.add('text-gray-300')
      }
    })
  }
}
