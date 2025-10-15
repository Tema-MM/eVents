{{ ... }}

export default class extends Controller {
  static targets = ["message"]

  connect() {
    // Prepare enter state
    this.element.classList.add("transition", "transform", "duration-300", "ease-out", "translate-x-4", "opacity-0")
    // Trigger enter animation on next frame
    requestAnimationFrame(() => {
      this.element.classList.remove("translate-x-4", "opacity-0")
    })

    // Auto-dismiss after 5 seconds
    this.timeout = setTimeout(() => this.close(), 5000)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  close() {
    if (!this.element) return
    // Leave animation
    this.element.classList.add("duration-200", "ease-in", "translate-x-4", "opacity-0")
    setTimeout(() => {
      this.element?.remove()
    }, 200)
  }
}
