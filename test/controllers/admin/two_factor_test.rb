require "test_helper"

class Admin::TwoFactorTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = users(:admin)
    @admin.update!(otp_required_for_login: false, otp_secret: nil)
  end

  test "admin access redirects to 2fa setup when not enabled" do
    sign_in @admin
    get admin_products_path
    assert_redirected_to admin_two_factor_path
    assert_equal I18n.t("admin.two_factor.required"), flash[:alert]
  end

  test "admin can enable two factor with valid otp" do
    sign_in @admin
    @admin.update!(otp_secret: User.generate_otp_secret)

    put admin_two_factor_path, params: { otp_attempt: @admin.current_otp }

    assert_redirected_to admin_two_factor_path
    assert @admin.reload.otp_required_for_login
    assert @admin.otp_backup_codes.present?
  end
end
