import "jquery"
import { confirmDestructiveAction } from "custom/destructive_confirmation"
import { appendPendingPatrons, canStagePatrons, openPatronPicker } from "custom/pending_patrons"

function saveIncident({ draft, addPatron }) {
    const data = new FormData()
    data.append("incident_id", $("#incident_id").text())
    data.append("draft", draft === "true")
    data.append("add_patron", addPatron === "true")

    for (const field of ["title", "description", "date_of", "location"]) {
        data.append(field, document.getElementById(field).value)
    }
    for (const summary of document.querySelectorAll(".violation-summary")) {
        data.append(summary.name, summary.value)
    }
    for (const image of document.getElementById("incident_images").files) {
        data.append("images[]", image)
    }
    if (canStagePatrons()) appendPendingPatrons(data)

    const buttons = $('[data-incident-action="save"], [data-incident-action="choose-patron"], [data-remove-pending-patron]').prop("disabled", true)
    $.ajax({
        url: "/incidents/save.js",
        method: "POST",
        data,
        contentType: false,
        processData: false
    }).always(() => buttons.prop("disabled", false))
}

const actions = {
    save: saveIncident,
    "choose-patron": () => openPatronPicker("new"),
    "clear-images": () => $("#incident_images").val(""),
    "delete-image": ({ imageId }, control) => confirmDestructiveAction(control, () => {
        $.post("/incidents/delete_image.js", { incident_id: $("#incident_id").text(), image_id: imageId })
    }),
    delete: ({ incidentId }, control) => confirmDestructiveAction(control, () => {
        $.post("/incidents/delete_incident.js", { id: incidentId })
    })
}

document.addEventListener("click", (event) => {
    const control = event.target.closest("[data-incident-action]")
    if (control && Object.hasOwn(actions, control.dataset.incidentAction)) {
        actions[control.dataset.incidentAction](control.dataset, control)
    }
})
