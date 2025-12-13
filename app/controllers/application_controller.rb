class ApplicationController < ActionController::Base
  include CartManagement

  after_action :transfer_cart_to_user, if: :user_signed_in?
end
