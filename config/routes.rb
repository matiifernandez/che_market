Rails.application.routes.draw do
  get 'products/index'
  get 'products/show'
  # get 'pages/home'
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  # Public
  root "pages#home"
  resources :products, only: [:index, :show]

  # Admin
  namespace :admin do
    root "dashboard#index"
    resources :products
    resources :categories
  end
end
