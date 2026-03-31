# frozen_string_literal: true

if defined?(Rails) && Rails.env.development?
  unless ENV["PATH"].to_s.include?("/opt/homebrew/bin")
    ENV["PATH"] = "/opt/homebrew/bin:#{ENV["PATH"]}"
  end
end
