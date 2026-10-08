import { Controller } from "@hotwired/stimulus"
import { playOverlayEnter, playOverlayExit, cancelOverlayHide } from "controllers/flat_pack/reduced_motion"

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

const OPTION_CLASSES = [
  "cursor-pointer px-3 py-2 text-sm",
  "text-[var(--surface-content-color)]",
  "aria-selected:bg-[var(--list-item-active-background-color)]",
  "hover:bg-[var(--list-item-hover-background-color)]"
].join(" ")

const MUTED_ROW_CLASSES = "px-3 py-2 text-sm text-[var(--surface-muted-content-color)]"

export default class extends Controller {
  static targets = [
    "input",
    "list",
    "attribution",
    "summary",
    "summaryTitle",
    "summaryDetail",
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
    this.openList = false
    this.debounceTimer = null
    this.abortController = null
    this.boundSearch = this.search.bind(this)
    this.boundKeydown = this.keydown.bind(this)
    this.boundOutside = this.outside.bind(this)

    if (this.hasInputTarget) {
      this.inputTarget.addEventListener("input", this.boundSearch)
      this.inputTarget.addEventListener("keydown", this.boundKeydown)
    }

    document.addEventListener("mousedown", this.boundOutside)

    if (this.fieldsTarget.querySelector("[aria-invalid='true']") && this.hasEditButtonTarget) {
      this.summaryTarget.classList.remove("hidden")
      this.editButtonTarget.click()
    }
  }

  disconnect() {
    this.clearDebounce()
    this.abortPending()
    cancelOverlayHide(this.listTarget)
    if (this.hasInputTarget) {
      this.inputTarget.removeEventListener("input", this.boundSearch)
      this.inputTarget.removeEventListener("keydown", this.boundKeydown)
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
      this.open()
      this.move(1)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.open()
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
    option.setAttribute("aria-selected", "false")
    option.className = OPTION_CLASSES
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
    option.setAttribute("aria-selected", "false")
    option.className = OPTION_CLASSES
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
    const modal = this.element.querySelector("[data-controller~='flat-pack--modal']")
    const controller = modal
      ? this.application.getControllerForElementAndIdentifier(modal, "flat-pack--modal")
      : null

    if (!controller || typeof controller.open !== "function") return

    controller.previousActiveElement = this.hasInputTarget ? this.inputTarget : document.activeElement
    controller.open()
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
    if (this.openList) return

    this.openList = true
    this.inputTarget?.setAttribute("aria-expanded", "true")
    playOverlayEnter(this.listTarget, { placement: "bottom" })
  }

  close() {
    if (!this.openList) {
      this.listTarget.classList.add("hidden")
      return
    }

    this.openList = false
    this.inputTarget?.setAttribute("aria-expanded", "false")
    this.inputTarget?.removeAttribute("aria-activedescendant")
    this.activeIndex = -1
    playOverlayExit(this.listTarget, { placement: "bottom" })
  }

  resetList() {
    this.results = []
    this.listTarget.replaceChildren()
  }

  showStatus(text) {
    this.resetList()
    const row = document.createElement("li")
    row.className = MUTED_ROW_CLASSES
    row.textContent = text
    this.listTarget.append(row)
    this.open()
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
      option.setAttribute("aria-selected", active ? "true" : "false")
      if (active && option.id) this.inputTarget?.setAttribute("aria-activedescendant", option.id)
    })
  }

  visibleOptions() {
    return Array.from(this.listTarget.querySelectorAll('[role="option"]'))
  }

  outside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  query() {
    return (this.hasInputTarget ? this.inputTarget.value : "").trim()
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
