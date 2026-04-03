require "test_helper"

class UserOtpKeyTest < ActiveSupport::TestCase
  def setup
    @original_user = User
  end

  def teardown
    Object.send(:remove_const, :User) if Object.const_defined?(:User)
    Object.const_set(:User, @original_user)
  end

  test "allows missing otp key in development" do
    reload_user_with_env("development")
    assert Object.const_defined?(:User)
  end

  test "raises when otp key missing in production" do
    error = assert_raises(RuntimeError) do
      reload_user_with_env("production")
    end
    assert_match(/Missing OTP secret encryption key/, error.message)
  end

  private

  def reload_user_with_env(env_name)
    creds = Rails.application.credentials
    old_env = ENV["DEVISE_OTP_SECRET_KEY"]
    ENV.delete("DEVISE_OTP_SECRET_KEY")

    Rails.stub(:env, ActiveSupport::StringInquirer.new(env_name)) do
      creds.stub(:dig, nil) do
        Object.send(:remove_const, :User) if Object.const_defined?(:User)
        load Rails.root.join("app/models/user.rb")
      end
    end
  ensure
    ENV["DEVISE_OTP_SECRET_KEY"] = old_env if old_env
  end
end
