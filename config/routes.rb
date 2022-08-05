Rails.application.routes.draw do
  get 'patron/save'
  get 'patron/edit'
  get 'patron/list'
  get 'patron/show'
  get 'main/index'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "main#index"

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

  #Patrons
  match '/patrons/save', to: 'patrons#save', via: [:post]
  match '/patrons/edit', to: 'patrons#edit', via: [:post]
  match '/patrons/load_violation_modal', to: 'patrons#load_violation_modal', via: [:post] 
  match '/patrons/save_violations', to: 'patrons#save_violations', via: [:post]
  match '/patrons/remove_violation', to: 'patrons#remove_violation', via: [:post]
  match '/patrons/remove_patron_from_incident', to: 'patrons#remove_patron_from_incident', via: [:post]
end
