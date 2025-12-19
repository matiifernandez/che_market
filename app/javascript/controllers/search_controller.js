import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search"
export default class extends Controller {
  static targets = ["input", "results"]
  static values = {
    url: String,
    debounce: { type: Number, default: 300 }
  }

  connect() {
    this.timeout = null
  }

  search() {
    clearTimeout(this.timeout)

    this.timeout = setTimeout(() => {
      this.performSearch()
    }, this.debounceValue)
  }

  performSearch() {
    const query = this.inputTarget.value.trim()
    const url = new URL(this.urlValue, window.location.origin)

    if (query) {
      url.searchParams.set("q", query)
    }

    // Keep existing category filter if present
    const currentUrl = new URL(window.location.href)
    const category = currentUrl.searchParams.get("category")
    if (category) {
      url.searchParams.set("category", category)
    }

    // Use Turbo to fetch and update the frame
    const frame = document.getElementById("products-grid")
    if (frame) {
      frame.src = url.toString()
    }
  }

  // Clear search
  clear() {
    this.inputTarget.value = ""
    this.performSearch()
  }
}
