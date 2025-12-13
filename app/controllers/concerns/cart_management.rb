module CartManagement
  extend ActiveSupport::Concern

  included do
    helper_method :current_cart
  end

  private

  def current_cart
    @current_cart ||= find_or_create_cart
  end

  def find_or_create_cart
    if session[:cart_secret_id]
      cart = Cart.find_by(secret_id: session[:cart_secret_id])
      return cart if cart
    end

    if user_signed_in? && current_user.cart
      cart = current_user.cart
      session[:cart_secret_id] = cart.secret_id
      return cart
    end

    create_new_cart
  end

  def create_new_cart
    cart = Cart.create(user: current_user)
    session[:cart_secret_id] = cart.secret_id
    cart
  end

  def transfer_cart_to_user
    return unless user_signed_in?
    return unless session[:cart_secret_id]

    guest_cart = Cart.find_by(secret_id: session[:cart_secret_id])
    return unless guest_cart && guest_cart.user.nil?

    if current_user.cart
      # Merge items from guest cart to user's cart
      guest_cart.cart_items.each do |item|
        current_user.cart.add_product(item.product, item.quantity)
      end
      guest_cart.destroy
      session[:cart_secret_id] = current_user.cart.secret_id
    else
      guest_cart.update(user: current_user)
    end
  end
end
