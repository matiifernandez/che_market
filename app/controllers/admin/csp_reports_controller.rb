# frozen_string_literal: true

class Admin::CspReportsController < Admin::BaseController
  def index
    @csp_reports = CspReport.order(occurred_at: :desc).limit(200)
  end
end
