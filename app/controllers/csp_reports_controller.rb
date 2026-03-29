# frozen_string_literal: true

class CspReportsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    report_payload = params[:csp_report] || params["csp-report"] || {}
    report = report_payload.is_a?(ActionController::Parameters) ? report_payload.to_unsafe_h : report_payload

    CspReport.create!(
      document_uri: report["document-uri"],
      referrer: report["referrer"],
      violated_directive: report["violated-directive"],
      effective_directive: report["effective-directive"],
      original_policy: report["original-policy"],
      blocked_uri: report["blocked-uri"],
      source_file: report["source-file"],
      status_code: report["status-code"],
      disposition: report["disposition"],
      occurred_at: Time.current,
      raw: report,
      user_agent: request.user_agent,
      ip_address: request.remote_ip
    )

    if report["violated-directive"].present? &&
       report["violated-directive"].exclude?("report-uri") &&
       report["violated-directive"].exclude?("report-to")
      Rails.logger.warn("[CSP] #{report['violated-directive']} blocked #{report['blocked-uri']} on #{report['document-uri']}")
    end

    head :no_content
  rescue StandardError => e
    Rails.logger.error("[CSP] Report failed: #{e.class} #{e.message}")
    head :no_content
  end
end
