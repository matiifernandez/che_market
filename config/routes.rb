Rails.application.routes.draw do
  # Email preview (development only)
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  # Webhooks
  post "/webhooks/stripe", to: "webhooks#stripe"

  # Sitemap
  get "sitemap", to: "sitemaps#index", as: :sitemap, defaults: { format: :xml }

  devise_for :users

  # Account
  resource :account, only: [:show, :edit, :update], controller: 'account' do
    get :orders
    get 'orders/:id', action: :order, as: :order
  end

  root "pages#home"

  # Legal pages
  get "terms", to: "pages#terms", as: :terms
  get "privacy", to: "pages#privacy", as: :privacy

  # Cart
  resource :cart, only: [:show] do
    post "add/:product_id", to: "carts#add_item", as: :add_item
    delete "remove/:product_id", to: "carts#remove_item", as: :remove_item
    patch "update/:product_id", to: "carts#update_item", as: :update_item
    post "coupon", to: "coupons#apply", as: :apply_coupon
    delete "coupon", to: "coupons#remove", as: :remove_coupon
    post "gift_card", to: "gift_card_applications#create", as: :apply_gift_card
    delete "gift_card", to: "gift_card_applications#destroy", as: :remove_gift_card
  end

  # Gift Cards
  resources :gift_cards, only: [:index, :new, :create] do
    collection do
      get :success
      get :check_balance
      post :balance
    end
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
    resources :coupons
    resources :gift_cards, only: [:index, :show] do
      member do
        post :cancel
        post :resend_email
      end
    end
  end
end
