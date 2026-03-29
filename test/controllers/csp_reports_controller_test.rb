require "test_helper"

class CspReportsControllerTest < ActionDispatch::IntegrationTest
  test "stores csp report payload" do
    payload = {
      "csp-report" => {
        "document-uri" => "https://example.com/products",
        "referrer" => "",
        "violated-directive" => "script-src",
        "effective-directive" => "script-src",
        "original-policy" => "default-src 'self'",
        "blocked-uri" => "https://evil.example.com",
        "source-file" => "https://example.com/app.js",
        "status-code" => 200,
        "disposition" => "enforce"
      }
    }

    assert_difference "CspReport.count", 1 do
      post csp_reports_path, params: payload, as: :json
    end

    assert_response :no_content
    report = CspReport.order(:id).last
    assert_equal "script-src", report.effective_directive
    assert_equal "https://evil.example.com", report.blocked_uri
    assert_equal "https://example.com/products", report.document_uri
    raw = report.raw
    effective = raw["effective-directive"] || raw["effective_directive"] || raw[:effective_directive] || raw[:effective_directive]
    blocked = raw["blocked-uri"] || raw["blocked_uri"] || raw[:blocked_uri]
    assert_equal "script-src", effective
    assert_equal "https://evil.example.com", blocked
  end
end
