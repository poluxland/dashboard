import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status"]

  connect() {
    this.pending = new Map()
    this.errors = new Map()
    this.selections = new Map()
    this.element.querySelectorAll("[data-inspection-toggle]").forEach(toggle => this.toggle(toggle))
  }

  toggle(toggle) {
    const questions = toggle.closest("[data-inspection]").querySelector("[data-inspection-questions]")
    questions.hidden = questions.disabled = !toggle.checked
    toggle.setAttribute("aria-expanded", String(toggle.checked))
  }

  change(event) {
    const input = event.target
    if (input.matches("[data-inspection-toggle]")) this.toggle(input)
    if (!input.matches("[data-compress-photo]")) return
    this.errors.delete(input)
    const selection = Symbol()
    this.selections.set(input, selection)
    const files = Array.from(input.files)
    const task = (async () => {
      this.statusTarget.textContent = "Optimizando fotos…"
      try {
        const transfer = new DataTransfer()
        // Process sequentially to limit memory usage on phones.
        for (const file of files) transfer.items.add(await this.compress(file))
        if (this.selections.get(input) !== selection) return
        input.files = transfer.files
        this.statusTarget.textContent = "Fotos listas para guardar."
      } catch (error) {
        if (this.selections.get(input) !== selection) return
        const message = error.message.startsWith("Selecciona") || error.message.startsWith("No se pudo")
          ? error.message : "No se pudo leer una foto. Selecciona otra imagen JPG, PNG o WEBP."
        this.errors.set(input, message)
        this.statusTarget.textContent = message
      }
    })()
    this.pending.set(input, task)
  }

  async compress(file) {
    if (!["image/jpeg", "image/png", "image/webp"].includes(file.type)) {
      throw new Error("Selecciona fotos JPG, PNG o WEBP.")
    }
    const url = URL.createObjectURL(file)
    try {
      const image = new Image()
      image.src = url
      await image.decode()
      const scale = Math.min(1, 1600 / Math.max(image.naturalWidth, image.naturalHeight))
      const canvas = document.createElement("canvas")
      canvas.width = Math.max(1, Math.round(image.naturalWidth * scale))
      canvas.height = Math.max(1, Math.round(image.naturalHeight * scale))
      const context = canvas.getContext("2d")
      context.fillStyle = "#fff"
      context.fillRect(0, 0, canvas.width, canvas.height)
      context.drawImage(image, 0, 0, canvas.width, canvas.height)
      const blob = await new Promise(resolve => canvas.toBlob(resolve, "image/jpeg", 0.72))
      if (!blob) throw new Error("No se pudo optimizar una foto. Vuelve a seleccionarla.")
      canvas.width = canvas.height = 1
      if (file.size <= blob.size && file.size <= 1024 * 1024) return file
      return new File([blob], file.name.replace(/\.[^.]+$/, "") + ".jpg", { type: "image/jpeg", lastModified: file.lastModified })
    } finally {
      URL.revokeObjectURL(url)
    }
  }

  async submit(event) {
    if (this.ready) { this.ready = false; return }
    event.preventDefault()
    event.stopImmediatePropagation()
    if (this.submitting) return
    this.submitting = true
    try {
      await Promise.all(this.pending.values())
      const errors = Array.from(this.errors).filter(([input]) => !input.matches(":disabled"))
      if (errors.length) {
        this.statusTarget.textContent = errors[0][1]
        errors[0][0].focus()
        return
      }
      // Leave the original submit event before requesting a new submission.
      await new Promise(resolve => setTimeout(resolve, 0))
      this.ready = true
      this.element.requestSubmit(event.submitter)
    } finally {
      this.submitting = false
    }
  }
}
