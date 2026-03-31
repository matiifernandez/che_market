# frozen_string_literal: true

unless ENV["PATH"].to_s.include?("/opt/homebrew/bin")
  ENV["PATH"] = "/opt/homebrew/bin:#{ENV["PATH"]}"
end
