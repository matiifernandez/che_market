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
  end
end
