import "jquery"
import "popper"
import "bootstrap"
import "custom/incidents"
import "custom/patrons"

const $ = window.jQuery
const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
const nonce = document.querySelector("meta[name='csp-nonce']")?.content

$.ajaxSetup({
  headers: { "X-CSRF-Token": csrfToken },
  converters: {
    "text script": function (response) {
      // Rails returns same-origin .js.erb updates for forms and dialogs.
      $.globalEval(response, { nonce })
      return response
    }
  }
})

document.addEventListener("submit", (event) => {
  if (event.submitter?.matches("[data-confirm-delete]") && !window.confirm("Delete this comment?")) {
    event.preventDefault()
  }
})

const feedback = document.querySelector("[data-request-feedback]")
if (feedback) {
  $(document).on("ajaxSend", () => {
    feedback.hidden = true
  }).on("ajaxError", (_event, response) => {
    if (response.status === 401) {
      feedback.textContent = "Your staff session expired. Open the sign-in page in a new tab, then try again."
    } else if (response.status === 403 || response.status === 404) {
      feedback.textContent = "The record is unavailable or you do not have permission to change it."
    } else {
      feedback.textContent = "The request didn’t complete. Check the record before trying again."
    }
    feedback.hidden = false
  })
}
