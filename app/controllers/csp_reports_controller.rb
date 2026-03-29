# frozen_string_literal: true

class CspReportsController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :set_locale
  skip_after_action :transfer_cart_to_user
  MAX_REPORT_BYTES = 32.kilobytes

  def create
    if request.content_length.to_i > MAX_REPORT_BYTES
      head :payload_too_large
      return
    end

    report = extract_report(params)

    CspReport.create!(
      document_uri: report_value(report, "document-uri", "document_uri", "documentURI"),
      referrer: report_value(report, "referrer"),
      violated_directive: report_value(report, "violated-directive", "violated_directive", "violatedDirective"),
      effective_directive: report_value(report, "effective-directive", "effective_directive", "effectiveDirective"),
      original_policy: report_value(report, "original-policy", "original_policy", "originalPolicy"),
      blocked_uri: report_value(report, "blocked-uri", "blocked_uri", "blockedURI"),
      source_file: report_value(report, "source-file", "source_file", "sourceFile"),
      status_code: report_value(report, "status-code", "status_code", "statusCode"),
      disposition: report_value(report, "disposition"),
      occurred_at: Time.current,
      raw: report,
      user_agent: request.user_agent,
      ip_address: request.remote_ip
    )

    violated_directive = report_value(report, "violated-directive", "violated_directive", "violatedDirective")
    blocked_uri = report_value(report, "blocked-uri", "blocked_uri", "blockedURI")
    document_uri = report_value(report, "document-uri", "document_uri", "documentURI")

    if violated_directive.present? &&
       violated_directive.exclude?("report-uri") &&
       violated_directive.exclude?("report-to")
      Rails.logger.info(
        "[CSP] Violation",
        violated_directive: safe_log_value(violated_directive),
        blocked_uri: safe_log_value(blocked_uri),
        document_uri: safe_log_value(document_uri)
      )
    end

    head :no_content
  rescue StandardError => e
    Rails.logger.error("[CSP] Report failed: #{e.class} #{e.message}")
    head :no_content
  end

  def safe_log_value(value)
    return nil if value.blank?
    value.to_s.gsub(/[\r\n]/, " ").strip.first(500)
  end

  def report_value(report, *keys)
    keys.each do |key|
      return report[key] if report.key?(key)
      symbol_key = key.to_sym
      return report[symbol_key] if report.key?(symbol_key)
    end
    nil
  end

  def extract_report(params_hash)
    candidates = [
      params_hash[:csp_report],
      params_hash["csp_report"],
      params_hash["csp-report"],
      params_hash[:_json],
      params_hash["_json"],
      params_hash[:report],
      params_hash["report"]
    ].compact

    candidates << params_hash.to_unsafe_h if params_hash.respond_to?(:to_unsafe_h)

    report_payload = candidates.find { |candidate| candidate.is_a?(Hash) } || {}
    report_payload = report_payload.to_unsafe_h if report_payload.is_a?(ActionController::Parameters)

    if report_payload.is_a?(Hash) && report_payload["csp-report"].is_a?(Hash)
      report_payload = report_payload["csp-report"]
    end

    if report_payload.is_a?(Hash) && report_payload["csp_report"].is_a?(Hash)
      report_payload = report_payload["csp_report"]
    end

    if report_payload.is_a?(Hash) && report_payload["body"].is_a?(Hash)
      report_payload = report_payload["body"]
    end

    report_payload
  end
end
