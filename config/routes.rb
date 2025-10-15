Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  root "events#index"
  resources :events, only: [:show, :edit, :update, :new, :create]
  get "/checkout/:id", to: "checkouts#show", as: :checkout
  post "/checkout/create_session", to: "checkouts#create_session", as: :checkout_create_session
  get "/checkout/success", to: "checkouts#complete", as: :checkout_success
  get "/checkout/simulate", to: "checkouts#simulate", as: :checkout_simulate
  post "/checkout/simple", to: "checkouts#simple", as: :checkout_simple
  get '/all-events', to: 'events#all', as: :all_events
  post '/purchases', to: 'purchases#create'

  # Cart routes
  get '/cart', to: 'carts#show', as: :cart
  post '/cart/add_item', to: 'carts#add_item'
  post '/cart/remove_item', to: 'carts#remove_item'
  delete '/cart/clear', to: 'carts#clear'
  post '/cart/purchase', to: 'carts#purchase', as: :purchase_cart

  # Confirmation route
  get '/confirmation', to: 'confirmations#show', as: :confirmation

  # My Tickets page
  get '/my-tickets', to: 'tickets#index', as: :my_tickets

  # Account page
  get '/account', to: 'accounts#show', as: :account

  # Ticket routes
  get '/download_tickets', to: 'tickets#download', as: :download_tickets
  post '/send_tickets', to: 'tickets#send_email', as: :send_tickets

  # Cart routes (extra)
  post '/cart/set_type', to: 'carts#set_type', as: :cart_set_type

  # Admin routes
  get '/admin/dashboard', to: 'events#admin_dashboard', as: :admin_dashboard_events
end