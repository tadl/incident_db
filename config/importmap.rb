# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "jquery", to: "https://code.jquery.com/jquery-3.6.0.min.js", preload: true
pin_all_from "app/javascript/custom", under: "custom"
pin "popper", to: 'popper.js', preload: true
pin "bootstrap", to: 'bootstrap.min.js', preload: true