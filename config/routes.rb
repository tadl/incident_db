Rails.application.routes.draw do
  get "up", to: "rails/health#show"
  root "incidents#all"

  get "sign_in", to: "sessions#new"
  get "auth/google_oauth2/callback", to: "sessions#create"
  get "auth/failure", to: "sessions#failure"
  post "signout", to: "sessions#destroy"

  get "attachments/:id", to: "attachments#show", as: :private_attachment, format: false
  get "attachments/:id/thumbnail", to: "attachments#thumbnail", as: :private_thumbnail, format: false

  get "main/index", to: redirect("/")
  get "old/list"
  get "old/view"
  match "old/search", to: "old#search", via: [:get, :post]

  get "incidents", to: "incidents#all"
  get "incidents/new"
  post "incidents/save"
  get "incidents/view"
  get "incidents/edit"
  post "incidents/delete_image"
  post "incidents/delete_incident"
  match "incidents/search", to: "incidents#search", via: [:get, :post]

  post "patrons/save"
  match "patrons/edit", to: "patrons#edit", via: [:get, :post]
  get "patrons/view"
  get "patrons/list"
  get "patrons/suspension_calendar"
  match "patrons/search", to: "patrons#search", via: [:get, :post]
  post "patrons/remove_patron_from_incident"
  post "patrons/delete_image"
  post "patrons/load_patron_search"
  post "patrons/load_new_patron_form"
  post "patrons/add_existing_to_incident"
  post "patrons/load_suspension_form"
  post "patrons/save_suspension"
  post "patrons/delete_suspension"
  post "patrons/delete_letter"
  post "patrons/delete_patron"

  post "comments/save"
  post "comments/delete"
  post "comments/update"
end
