// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import 'jquery'
import "popper"
import "bootstrap"

const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
if (csrfToken && window.$) {
  window.$.ajaxSetup({
    headers: {
      "X-CSRF-Token": csrfToken
    }
  })
}

import 'custom/admin'
import 'custom/incidents'
import 'custom/patrons'
import 'custom/comments'
import 'custom/old'
