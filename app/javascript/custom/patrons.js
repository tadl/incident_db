import "jquery"
import { confirmDestructiveAction } from "custom/destructive_confirmation"
import { canStagePatrons, closePatronPicker, openPatronPicker, stageExistingPatron, stageNewPatron } from "custom/pending_patrons"

const incidentId = () => $("#incident_id").text()

function savePatron({ patronId = "" }) {
    const data = new FormData()
    if (incidentId()) data.append("incident_id", incidentId())
    if (patronId) data.append("patron_id", patronId)

    const fields = {
        first_name: "first_name",
        middle_name: "middle_name",
        last_name: "last_name",
        known_as: "alias",
        address: "address",
        city: "city",
        state: "state",
        zip: "zip",
        card_number: "card_number",
        description: "patron_description"
    }
    for (const [name, input] of Object.entries(fields)) {
        data.append(name, document.getElementById(`${input}_${patronId}`).value)
    }
    for (const file of document.getElementById(`patron_images_${patronId}`).files) {
        data.append("images[]", file)
    }

    if (canStagePatrons()) {
        stageNewPatron(data)
    } else {
        uploadPatronForm("/patrons/save.js", data)
    }
}

function saveSuspension({ patronId }) {
    const data = new FormData()
    data.append("incident_id", incidentId())
    data.append("patron_id", patronId)
    data.append("suspension_id", $(`#suspension_id_${patronId}`).text())
    data.append("until", $(`#until_${patronId}`).val())
    data.append("letter_sent", $(`#letter_sent_${patronId}`).is(":checked"))
    data.append("call_police", $(`#call_police_${patronId}`).is(":checked"))

    const letter = document.getElementById(`letter_${patronId}`)?.files[0]
    if (letter) data.append("letter", letter)

    uploadPatronForm("/patrons/save_suspension.js", data)
}

function uploadPatronForm(url, data) {
    const buttons = $('[data-patron-action="save"], [data-patron-action="save-suspension"]').prop("disabled", true)
    $.ajax({ url, method: "POST", data, contentType: false, processData: false })
        .always(() => buttons.prop("disabled", false))
}

function postIncidentPatron(action, { patronId, imageId, suspensionId } = {}) {
    const data = {
        incident_id: incidentId(),
        patron_id: patronId,
        image_id: imageId,
        suspension_id: suspensionId
    }
    return $.post(`/patrons/${action}.js`, data)
}

function searchIncidentPatrons() {
    $.post("/patrons/search.js", {
        incident_id: incidentId(),
        pending_incident: canStagePatrons(),
        query: $("#patron_query").val()
    })
}

const actions = {
    save: savePatron,
    "save-suspension": saveSuspension,
    cancel: closePatronPicker,
    remove: (data, control) => confirmDestructiveAction(control, () => postIncidentPatron("remove_patron_from_incident", data)),
    edit: (data) => postIncidentPatron("edit", data),
    "clear-images": ({ patronId = "" }) => $(`#patron_images_${patronId}`).val(""),
    "delete-image": (data, control) => confirmDestructiveAction(control, () => postIncidentPatron("delete_image", data)),
    "load-search": () => canStagePatrons() ? openPatronPicker("search") : postIncidentPatron("load_patron_search"),
    search: searchIncidentPatrons,
    "load-new": () => canStagePatrons() ? openPatronPicker("new") : postIncidentPatron("load_new_patron_form"),
    add: (data) => canStagePatrons() ? stageExistingPatron(data) : postIncidentPatron("add_existing_to_incident", data),
    "suspension-form": (data) => postIncidentPatron("load_suspension_form", data),
    "delete-suspension": (data, control) => confirmDestructiveAction(control, () => postIncidentPatron("delete_suspension", data)),
    "clear-letter": ({ patronId }) => $(`#letter_${patronId}`).val(""),
    "delete-letter": (data, control) => confirmDestructiveAction(control, () => postIncidentPatron("delete_letter", data)),
    delete: ({ patronId }, control) => confirmDestructiveAction(control, () => $.post("/patrons/delete_patron.js", { id: patronId }))
}

document.addEventListener("click", (event) => {
    const control = event.target.closest("[data-patron-action]")
    if (control && Object.hasOwn(actions, control.dataset.patronAction)) {
        actions[control.dataset.patronAction](control.dataset, control)
    }
})

document.addEventListener("keydown", (event) => {
    if (event.target.id === "patron_query" && event.key === "Enter") {
        event.preventDefault()
        searchIncidentPatrons()
    }
})
