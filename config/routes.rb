Rails.application.routes.draw do
  devise_for :users

  root "pages#home"

  # Cart
  resource :cart, only: [:show] do
    post "add/:product_id", to: "carts#add_item", as: :add_item
    delete "remove/:product_id", to: "carts#remove_item", as: :remove_item
    patch "update/:product_id", to: "carts#update_item", as: :update_item
  end

  # Checkout
  resource :checkout, only: [:create] do
    get "success", on: :collection
    get "cancel", on: :collection
  end

  # Public products
  resources :products, only: [:index, :show]

  # Admin
  namespace :admin do
    root "dashboard#index"
    resources :products
    resources :categories
    resources :orders, only: [:index, :show, :update]
  end
end
