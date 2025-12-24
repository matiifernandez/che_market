ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

# Helper module for stubbing Stripe in tests
module StripeTestHelper
  def stub_stripe_construct_event(event)
    event_object = Stripe::Event.construct_from(event)

    original_method = Stripe::Webhook.method(:construct_event)
    Stripe::Webhook.define_singleton_method(:construct_event) do |*_args|
      event_object
    end

    yield
  ensure
    Stripe::Webhook.define_singleton_method(:construct_event, original_method)
  end

  def stub_stripe_session_create(session)
    original_method = Stripe::Checkout::Session.method(:create)
    Stripe::Checkout::Session.define_singleton_method(:create) do |*_args|
      session
    end

    yield
  ensure
    Stripe::Checkout::Session.define_singleton_method(:create, original_method)
  end

  def stub_stripe_session_retrieve(session)
    original_method = Stripe::Checkout::Session.method(:retrieve)
    Stripe::Checkout::Session.define_singleton_method(:retrieve) do |*_args|
      session
    end

    yield
  ensure
    Stripe::Checkout::Session.define_singleton_method(:retrieve, original_method)
  end
end
