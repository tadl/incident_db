import "jquery"

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

    const buttons = $('[data-incident-action="save"]').prop("disabled", true)
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
    "clear-images": () => $("#incident_images").val(""),
    "delete-image": ({ imageId }) => {
        $.post("/incidents/delete_image.js", { incident_id: $("#incident_id").text(), image_id: imageId })
    },
    delete: ({ incidentId }) => {
        if (confirm("Delete this incident?")) {
            $.post("/incidents/delete_incident.js", { id: incidentId })
        }
    }
}

document.addEventListener("click", (event) => {
    const control = event.target.closest("[data-incident-action]")
    if (control && Object.hasOwn(actions, control.dataset.incidentAction)) {
        actions[control.dataset.incidentAction](control.dataset)
    }
})
