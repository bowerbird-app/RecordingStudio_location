import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    typeIcons: { type: Object, default: {} }
  }

  typeChanged(event) {
    const input = event.target
    if (!(input instanceof HTMLInputElement) || input.type !== "radio") return
    if (!input.name.includes("[location_type]")) return

    const icon = this.typeIconsValue[input.value]
    if (!icon) return

    this.element.querySelectorAll('input[type="radio"][name$="[icon]"]').forEach((radio) => {
      radio.checked = radio.value === icon
    })
  }
}
