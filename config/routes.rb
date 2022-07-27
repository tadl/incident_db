Rails.application.routes.draw do
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

end
