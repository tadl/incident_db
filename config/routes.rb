Rails.application.routes.draw do
  get 'old/list'
  get 'old/view'
  get 'old/search'
  get 'patron/save'
  get 'patron/edit'
  get 'patron/list'
  get 'patron/show'
  get 'main/index'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "incidents#all"

  # Log in, failed login, log Out 
  match 'auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  match 'auth/failure', to: redirect('/'), via: [:get, :post]
  match 'signout', to: 'sessions#destroy', as: 'signout', via: [:get, :post]

  #Admin Pannel and Related Views
  match 'admin', to: 'main#admin_pannel', via: [:get, :post]
  match 'new_rule', to: 'admin#new_rule', via: [:post]
  match 'edit_rule', to: 'admin#edit_rule', via: [:post]
  match 'save_rule', to: 'admin#save_rule', via: [:post]

  #Incidents
  match 'incidents', to: 'incidents#all', via: [:get, :post]
  match '/incidents/new', to: 'incidents#new', via: [:get, :post]
  match '/incidents/save', to: 'incidents#save', via: [:post]
  match '/incidents/view', to: 'incidents#view', via: [:get, :post]
  match '/incidents/edit', to: 'incidents#edit', via: [:get, :post]
  match '/incidents/delete_image', to: 'incidents#delete_image', via: [:post]
  match '/incidents/delete_incident', to: 'incidents#delete_incident', via: [:post]
  match '/incidents/search', to: 'incidents#search', via: [:get, :post]

  #Patrons
  match '/patrons/save', to: 'patrons#save', via: [:post]
  match '/patrons/edit', to: 'patrons#edit', via: [:get, :post]
  match '/patrons/view', to: 'patrons#view', via: [:get, :post]
  match '/patrons/list', to: 'patrons#list', via: [:get, :post]
  match '/patrons/search', to: 'patrons#search', via: [:get, :post]
  match '/patrons/load_violation_modal', to: 'patrons#load_violation_modal', via: [:post] 
  match '/patrons/save_violations', to: 'patrons#save_violations', via: [:post]
  match '/patrons/remove_violation', to: 'patrons#remove_violation', via: [:post]
  match '/patrons/remove_patron_from_incident', to: 'patrons#remove_patron_from_incident', via: [:post]
  match '/patrons/delete_image', to: 'patrons#delete_image', via: [:post]
  match '/patrons/load_patron_search', to: 'patrons#load_patron_search', via: [:post]
  match '/patrons/load_new_patron_form', to: 'patrons#load_new_patron_form', via: [:post]
  match '/patrons/add_existing_to_incident', to: 'patrons#add_existing_to_incident', via: [:post]
  match '/patrons/load_suspension_form', to: 'patrons#load_suspension_form', via: [:post]
  match '/patrons/save_suspension', to: 'patrons#save_suspension', via: [:post]
  match '/patrons/delete_suspension', to: 'patrons#delete_suspension', via: [:post]
  match '/patrons/delete_letter', to: 'patrons#delete_letter', via: [:post]
  match '/patrons/delete_patron', to: 'patrons#delete_patron', via: [:post]

  #Comments
  match '/comments/save', to: 'comments#save', via: [:post]
  match '/comments/edit', to: 'comments#edit', via: [:post]
  match '/comments/delete', to: 'comments#delete', via: [:post]
  match '/comments/update', to: 'comments#update', via: [:post]

end
