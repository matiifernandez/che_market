# frozen_string_literal: true

# Ensure Active Record Encryption keys are present in development/test to avoid
# boot/runtime errors when encrypted attributes are used (e.g., OTP secrets).
Rails.application.config.to_prepare do
  encryption = Rails.application.config.active_record.encryption
  primary_key = encryption.primary_key
  deterministic_key = encryption.deterministic_key
  key_derivation_salt = encryption.key_derivation_salt

  if primary_key.blank? || deterministic_key.blank? || key_derivation_salt.blank?
    if Rails.env.development? || Rails.env.test?
      secret = Rails.application.secret_key_base
      generator = ActiveSupport::KeyGenerator.new(secret, iterations: 1000)

      encryption.primary_key ||= generator.generate_key("active_record_encryption_primary_key", 32)
      encryption.deterministic_key ||= generator.generate_key("active_record_encryption_deterministic_key", 32)
      encryption.key_derivation_salt ||= generator.generate_key("active_record_encryption_key_derivation_salt", 32)

      Rails.logger.warn("[Encryption] Active Record encryption keys missing; derived from secret_key_base in #{Rails.env}.")
    else
      raise "Missing Active Record encryption credentials. Set active_record_encryption.primary_key, " \
            "active_record_encryption.deterministic_key, and active_record_encryption.key_derivation_salt."
    end
  end
end
