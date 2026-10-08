import { Controller } from "@hotwired/stimulus"

const FIELD_NAMES = [
  "name",
  "address_line_1",
  "address_line_2",
  "locality",
  "region",
  "postal_code",
  "country_code",
  "latitude",
  "longitude"
]

export default class extends Controller {
  static targets = [
    "list",
    "status",
    "attribution",
    "summary",
    "summaryTitle",
    "summaryDetail",
    "manualButton",
    "editButton",
    "fields"
  ]

  static values = {
    searchUrl: String,
    detailsUrl: String,
    lookup: { type: String, default: "full" },
    session: String,
    minLength: { type: Number, default: 3 },
    debounce: { type: Number, default: 300 },
    listId: String,
    searchingText: { type: String, default: "Searching" },
    addManuallyText: { type: String, default: "Add address manually" }
  }

  connect() {
    this.activeIndex = -1
    this.results = []
    this.debounceTimer = null
    this.abortController = null
    this.input = this.element.querySelector("input[type='search']")
    this.boundSearch = this.search.bind(this)
    this.boundKeydown = this.keydown.bind(this)
    this.boundOutside = this.outside.bind(this)

    if (this.input) {
      this.input.setAttribute("role", "combobox")
      this.input.setAttribute("aria-autocomplete", "list")
      this.input.setAttribute("aria-expanded", "false")
      this.input.setAttribute("autocomplete", "off")
      if (this.listIdValue) this.input.setAttribute("aria-controls", this.listIdValue)
      this.input.addEventListener("input", this.boundSearch)
      this.input.addEventListener("keydown", this.boundKeydown)
    }

    document.addEventListener("mousedown", this.boundOutside)

    if (this.fieldsTarget.querySelector("[aria-invalid='true']")) {
      this.summaryTarget.classList.remove("hidden")
      this.editButtonTarget.click()
    }
  }

  disconnect() {
    this.clearDebounce()
    this.abortPending()
    if (this.input) {
      this.input.removeEventListener("input", this.boundSearch)
      this.input.removeEventListener("keydown", this.boundKeydown)
    }
    document.removeEventListener("mousedown", this.boundOutside)
  }

  search() {
    const query = this.query()

    if (query.length < this.minLengthValue) {
      this.resetList()
      this.close()
      return
    }

    this.clearDebounce()
    this.debounceTimer = setTimeout(() => this.fetchResults(query), this.debounceValue)
  }

  keydown(event) {
    if (event.key === "Escape") {
      this.close()
      return
    }

    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.move(1)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.move(-1)
    } else if (event.key === "Enter") {
      const option = this.visibleOptions()[this.activeIndex]
      if (option) {
        event.preventDefault()
        this.activate(option)
      }
    }
  }

  async fetchResults(query) {
    this.abortPending()
    this.abortController = new AbortController()
    this.showStatus(this.searchingTextValue)

    try {
      const url = new URL(this.searchUrlValue, window.location.origin)
      url.searchParams.set("q", query)
      if (this.sessionValue) url.searchParams.set("session", this.sessionValue)

      const response = await fetch(url.toString(), {
        headers: { Accept: "application/json" },
        signal: this.abortController.signal
      })

      if (!response.ok) {
        this.renderResults([])
        return
      }

      const payload = await response.json()
      const results = Array.isArray(payload.results) ? payload.results : []
      this.setAttribution(payload.attribution)
      this.renderResults(results)
    } catch (error) {
      if (error.name !== "AbortError") this.renderResults([])
    }
  }

  renderResults(results) {
    this.results = results
    this.listTarget.replaceChildren()
    this.hideStatus()

    if (results.length === 0) {
      this.listTarget.append(this.manualOption())
      this.open()
      this.activeIndex = 0
      this.syncActive()
      return
    }

    results.forEach((result, index) => {
      this.listTarget.append(this.resultOption(result, index))
    })
    this.open()
    this.activeIndex = 0
    this.syncActive()
  }

  resultOption(result, index) {
    const option = document.createElement("li")
    option.id = `${this.listIdValue}-option-${index}`
    option.setAttribute("role", "option")
    option.className = "cursor-pointer px-3 py-2 text-sm text-[var(--surface-content-color)] hover:bg-[var(--list-item-hover-background-color)]"
    option.textContent = result.label || result.name || ""
    option.dataset.id = result.id
    option.dataset.kind = "place"
    option.addEventListener("mousedown", (event) => {
      event.preventDefault()
      this.pick(result)
    })
    return option
  }

  manualOption() {
    const option = document.createElement("li")
    option.id = `${this.listIdValue}-manual`
    option.setAttribute("role", "option")
    option.className = "cursor-pointer px-3 py-2 text-sm text-[var(--surface-content-color)] hover:bg-[var(--list-item-hover-background-color)]"
    option.dataset.kind = "manual"
    option.textContent = this.addManuallyTextValue
    option.addEventListener("mousedown", (event) => {
      event.preventDefault()
      this.openManual()
    })
    return option
  }

  async pick(result) {
    this.close()
    if (!result?.id) return

    try {
      const url = new URL(this.detailsUrlValue, window.location.origin)
      url.searchParams.set("id", result.id)
      url.searchParams.set("lookup", this.lookupValue)
      if (this.sessionValue) url.searchParams.set("session", this.sessionValue)

      const response = await fetch(url.toString(), {
        headers: { Accept: "application/json" }
      })
      if (!response.ok) return

      const payload = await response.json()
      this.applyResult(payload, result)
    } catch (_error) {
      // Keep typed fields as they are if lookup fails.
    }
  }

  applyResult(payload, candidate) {
    const name = payload.name || candidate.name
    if (name) this.setField("name", name)

    FIELD_NAMES.filter((name) => name !== "name").forEach((field) => {
      if (Object.prototype.hasOwnProperty.call(payload, field)) {
        this.setField(field, payload[field])
      }
    })

    this.refreshSummary(payload, candidate)
  }

  setField(name, value) {
    const field = this.fieldsTarget.querySelector(`[name$="[${name}]"]`)
    if (!field) return

    const next = value == null ? "" : String(value)

    if (name === "country_code") {
      this.setCountry(field, next)
      return
    }

    field.value = next
    field.dispatchEvent(new Event("input", { bubbles: true }))
    field.dispatchEvent(new Event("change", { bubbles: true }))
  }

  setCountry(hidden, code) {
    const selectRoot = hidden.closest("[data-controller~='flat-pack--select']")
    const controller = selectRoot
      ? this.application.getControllerForElementAndIdentifier(selectRoot, "flat-pack--select")
      : null

    if (controller?.selectedValues) {
      controller.selectedValues.clear()
      if (code) controller.selectedValues.add(code)
      if (typeof controller.syncSelectedState === "function") controller.syncSelectedState()
      return
    }

    hidden.value = code
    hidden.dispatchEvent(new Event("change", { bubbles: true }))
  }

  refreshSummary(payload, candidate) {
    const title = payload.name || candidate.name || payload.formatted_address || candidate.label || ""
    const detail = payload.formatted_address || candidate.label || ""
    if (this.hasSummaryTitleTarget) this.summaryTitleTarget.textContent = title
    if (this.hasSummaryDetailTarget) this.summaryDetailTarget.textContent = detail === title ? "" : detail
    this.summaryTarget.classList.remove("hidden")
  }

  openManual() {
    this.close()
    this.manualButtonTarget.click()
  }

  activate(option) {
    if (option.dataset.kind === "manual") {
      this.openManual()
      return
    }

    const result = this.results.find((item) => item.id === option.dataset.id)
    if (result) this.pick(result)
  }

  open() {
    this.listTarget.classList.remove("hidden")
    this.input?.setAttribute("aria-expanded", "true")
  }

  close() {
    this.listTarget.classList.add("hidden")
    this.input?.setAttribute("aria-expanded", "false")
    this.input?.removeAttribute("aria-activedescendant")
    this.activeIndex = -1
  }

  resetList() {
    this.results = []
    this.listTarget.replaceChildren()
    this.hideStatus()
  }

  showStatus(text) {
    this.statusTarget.textContent = text
    this.statusTarget.classList.remove("hidden")
    this.listTarget.replaceChildren()
    this.open()
  }

  hideStatus() {
    this.statusTarget.classList.add("hidden")
  }

  setAttribution(attribution) {
    const text = attribution?.text
    if (!text) {
      this.attributionTarget.textContent = ""
      this.attributionTarget.classList.add("hidden")
      return
    }

    this.attributionTarget.textContent = text
    this.attributionTarget.classList.remove("hidden")
  }

  move(delta) {
    const options = this.visibleOptions()
    if (options.length === 0) return

    this.activeIndex = (this.activeIndex + delta + options.length) % options.length
    this.syncActive()
    options[this.activeIndex].scrollIntoView({ block: "nearest" })
  }

  syncActive() {
    const options = this.visibleOptions()
    options.forEach((option, index) => {
      const active = index === this.activeIndex
      option.classList.toggle("bg-[var(--list-item-hover-background-color)]", active)
      if (active && option.id) this.input?.setAttribute("aria-activedescendant", option.id)
    })
  }

  visibleOptions() {
    return Array.from(this.listTarget.querySelectorAll('[role="option"]'))
  }

  outside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  query() {
    return (this.input?.value || "").trim()
  }

  clearDebounce() {
    if (!this.debounceTimer) return
    clearTimeout(this.debounceTimer)
    this.debounceTimer = null
  }

  abortPending() {
    if (!this.abortController) return
    this.abortController.abort()
    this.abortController = null
  }
}
