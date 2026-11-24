const dialog = document.querySelector("[data-destructive-confirmation]")
const originalParent = dialog?.parentElement
let pending

export function confirmDestructiveAction(control, action) {
    if (typeof dialog?.showModal !== "function" || pending) return

    const { confirmTitle, confirmMessage, confirmLabel } = control.dataset
    dialog.querySelector("[data-confirmation-title]").textContent = confirmTitle
    dialog.querySelector("[data-confirmation-message]").textContent = confirmMessage
    dialog.querySelector("[data-confirmation-accept]").textContent = confirmLabel
    dialog.returnValue = ""

    // Keep the dialog inside an open Bootstrap modal's focus trap.
    const modal = control.closest(".modal.show")
    if (modal) modal.append(dialog)

    pending = { control, action }
    dialog.showModal()
}

if (dialog) {
    dialog.addEventListener("keydown", (event) => {
        if (event.key === "Escape") event.stopPropagation()
    })

    dialog.addEventListener("close", () => {
        if (!pending) return

        const { control, action } = pending
        const confirmed = dialog.returnValue === "confirm"
        pending = undefined

        if (dialog.parentElement !== originalParent) originalParent.append(dialog)
        if (!control.isConnected) return

        control.focus({ preventScroll: true })
        if (confirmed) action()
    })

    document.addEventListener("click", (event) => {
        const control = event.target.closest("[data-confirm-form]")
        if (control) confirmDestructiveAction(control, () => control.form.requestSubmit())
    })
}
