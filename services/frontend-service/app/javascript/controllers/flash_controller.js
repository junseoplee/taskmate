import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Auto-hide flash messages after 5 seconds
    setTimeout(() => {
      this.close()
    }, 5000)
  }

  close() {
    this.element.style.transition = "all 0.3s ease-out"
    this.element.style.transform = "translateX(100%)"
    this.element.style.opacity = "0"
    
    setTimeout(() => {
      if (this.element.parentNode) {
        this.element.parentNode.removeChild(this.element)
      }
    }, 300)
  }
}