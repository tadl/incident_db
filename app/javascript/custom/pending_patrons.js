import "jquery"

const pendingPatrons = new Map()
let nextNewPatron = 0

export function canStagePatrons() {
    return document.getElementById("incident_id")?.textContent.trim() === ""
}

export function openPatronPicker(mode) {
    const template = document.querySelector(`template[data-pending-patron-picker="${mode}"]`)
    const picker = document.getElementById("add_patron")
    picker.replaceChildren(template.content.cloneNode(true))
    $(picker).show().find("input").first().trigger("focus")
    $("#add_patron_to_incident_button, #save_incident_buttons").hide()
}

export function closePatronPicker() {
    $("#add_patron").empty().hide()
    $("#add_patron_to_incident_button, #save_incident_buttons").show()
    $("#add_patron_to_incident_button button").trigger("focus")
}

export function stageExistingPatron({ patronId, patronName }) {
    const data = new FormData()
    data.append("patron_id", patronId)
    stagePatron(`existing-${patronId}`, data, patronName || "Unknown patron")
}

export function stageNewPatron(data) {
    const name = ["first_name", "middle_name", "last_name"].map((field) => data.get(field).trim()).filter(Boolean).join(" ")
    const alias = data.get("known_as").trim()
    if (!name && !alias) {
        $("#patron_messages_").text("Enter at least one name or an alias.").addClass("text-danger")
        return
    }

    stagePatron(`new-${nextNewPatron++}`, data, name || alias)
}

function stagePatron(key, data, name) {
    if (!pendingPatrons.has(key)) {
        const card = document.querySelector("template[data-pending-patron-card]").content.firstElementChild.cloneNode(true)
        const note = card.querySelector("[data-pending-violation-summary]")
        card.querySelector("[data-pending-patron-name]").textContent = name
        card.querySelector("[data-remove-pending-patron]").addEventListener("click", () => {
            pendingPatrons.delete(key)
            card.remove()
            $("#add_patron_to_incident_button button").trigger("focus")
        })
        pendingPatrons.set(key, { data, note })
        document.getElementById("patron_list").append(card)
    }
    closePatronPicker()
}

export function appendPendingPatrons(form) {
    let index = 0
    for (const { data, note } of pendingPatrons.values()) {
        const prefix = `pending_patrons[${index++}]`
        for (const [attribute, value] of data) {
            const field = attribute === "images[]" ? "[images][]" : `[${attribute}]`
            form.append(prefix + field, value)
        }
        form.append(`${prefix}[violation_summary]`, note.value)
    }
}
