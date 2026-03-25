require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  test "should get index as xml" do
    get sitemap_url
    assert_response :success
    assert_equal "application/xml; charset=utf-8", response.content_type
  end

  test "sitemap includes correct structure and alternates" do
    get sitemap_url
    
    # Check for basic sitemap tags
    assert_match /<urlset xmlns="http:\/\/www.sitemaps.org\/schemas\/sitemap\/0.9"/, response.body
    assert_match /xmlns:xhtml="http:\/\/www.w3.org\/1999\/xhtml"/, response.body
    
    # Check for home page entry (matching only the path to be host-agnostic)
    assert_match /<loc>http:\/\/.*\/<\/loc>/, response.body
    
    # Check for xhtml:link alternates (es, en, x-default)
    assert_match /xhtml:link rel="alternate" hreflang="es" href="http:\/\/.*\/\"/, response.body
    assert_match /xhtml:link rel="alternate" hreflang="en" href="http:\/\/.*\/\?locale=en\"/, response.body
    assert_match /xhtml:link rel="alternate" hreflang="x-default" href="http:\/\/.*\/\"/, response.body
  end

  test "sitemap includes products" do
    product = products(:one)
    get sitemap_url
    
    assert_match /<loc>http:\/\/.*\/products\/#{product.id}<\/loc>/, response.body
    # Alternate for product
    assert_match /xhtml:link rel="alternate" hreflang="en" href="http:\/\/.*\/products\/#{product.id}\?locale=en\"/, response.body
  end

  test "sitemap includes published landing pages only" do
    published_page = LandingPage.create!(
      title: "Landing SEO",
      slug: "landing-seo",
      published: true
    )
    LandingPage.create!(
      title: "Landing draft",
      slug: "landing-draft",
      published: false
    )

    get sitemap_url

    assert_match /<loc>http:\/\/.*\/l\/#{published_page.slug}<\/loc>/, response.body
    assert_no_match /<loc>http:\/\/.*\/l\/landing-draft<\/loc>/, response.body
    assert_match /xhtml:link rel="alternate" hreflang="en" href="http:\/\/.*\/l\/#{published_page.slug}\?locale=en\"/, response.body
  end
end
