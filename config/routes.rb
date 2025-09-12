Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  root "events#index"
  resources :events, only: [:show, :edit, :update, :new, :create]
  get "/checkout/:id", to: "checkouts#show", as: :checkout
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

  # Ticket routes
  get '/download_tickets', to: 'tickets#download', as: :download_tickets
  get '/send_tickets', to: 'tickets#send_email', as: :send_tickets

  # Admin routes
  get '/admin/dashboard', to: 'events#admin_dashboard', as: :admin_dashboard_events
end