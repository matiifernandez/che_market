# frozen_string_literal: true

Rails.application.config.x.fraud = ActiveSupport::OrderedOptions.new
Rails.application.config.x.fraud.window_minutes = ENV.fetch("CHECKOUT_VELOCITY_WINDOW_MINUTES", 15).to_i
Rails.application.config.x.fraud.max_per_ip = ENV.fetch("CHECKOUT_VELOCITY_MAX_PER_IP", 3).to_i
Rails.application.config.x.fraud.max_per_user = ENV.fetch("CHECKOUT_VELOCITY_MAX_PER_USER", 3).to_i
Rails.application.config.x.fraud.max_per_email = ENV.fetch("CHECKOUT_VELOCITY_MAX_PER_EMAIL", 3).to_i
