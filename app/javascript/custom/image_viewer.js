const dialog = document.querySelector("[data-image-viewer]")

if (typeof dialog?.showModal === "function") {
  const title = dialog.querySelector("[data-image-viewer-title]")
  const image = dialog.querySelector("[data-image-viewer-picture]")
  const original = dialog.querySelector("[data-image-viewer-original]")
  const status = dialog.querySelector("[data-image-viewer-status]")
  let opener
  let pressedBackdrop = false

  const isBackdrop = (event) => {
    if (event.target !== dialog) return false

    const { left, top, right, bottom } = dialog.getBoundingClientRect()
    return event.clientX < left || event.clientX >= right || event.clientY < top || event.clientY >= bottom
  }

  dialog.addEventListener("pointerdown", (event) => {
    pressedBackdrop = event.button === 0 && isBackdrop(event)
  })

  dialog.addEventListener("pointercancel", () => {
    pressedBackdrop = false
  })

  dialog.addEventListener("click", (event) => {
    if (pressedBackdrop && isBackdrop(event)) dialog.close()
    pressedBackdrop = false
  })

  document.addEventListener("click", (event) => {
    if (event.defaultPrevented || event.button !== 0 || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return

    const link = event.target.closest?.("a[data-image-preview]")
    // An open Bootstrap modal already owns keyboard focus.
    if (!link || link.closest(".modal.show") || dialog.open) return

    const url = new URL(link.href)
    if (url.origin !== window.location.origin) return

    opener = link
    title.textContent = link.dataset.imagePreview
    original.href = url.href
    image.hidden = true
    status.textContent = "Loading image…"
    status.hidden = false
    dialog.showModal()
    image.src = url.href
    event.preventDefault()
  })

  image.addEventListener("load", () => {
    if (!dialog.open) return

    image.hidden = false
    status.hidden = true
  })

  image.addEventListener("error", () => {
    if (!dialog.open) return

    status.textContent = "The image couldn’t be loaded."
  })

  dialog.addEventListener("close", () => {
    if (dialog.open) return

    image.hidden = true
    image.removeAttribute("src")
    original.removeAttribute("href")
    opener?.focus({ preventScroll: true })
    opener = undefined
    pressedBackdrop = false
  })
}
