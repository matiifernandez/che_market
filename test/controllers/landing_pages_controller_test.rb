require "test_helper"

class LandingPagesControllerTest < ActionDispatch::IntegrationTest
  test "shows published landing page" do
    page = LandingPage.create!(
      title: "Yerba organica",
      slug: "yerba-organica",
      hero_subtitle: "Beneficios y productos recomendados",
      published: true
    )

    get landing_page_url(page.slug)
    assert_response :success
    assert_match page.title, response.body
  end

  test "returns 404 for unpublished landing page" do
    page = LandingPage.create!(
      title: "Yerba premium",
      slug: "yerba-premium",
      published: false
    )

    get landing_page_url(page.slug)
    assert_response :not_found
  end

  test "product grid shows only available products" do
    available_product = products(:one)
    inactive_product = products(:inactive)
    page = LandingPage.create!(
      title: "Yerba comparativa",
      slug: "yerba-comparativa",
      published: true,
      blocks: [
        { "type" => "product_grid", "product_ids" => [available_product.id, inactive_product.id] }
      ]
    )

    get landing_page_url(page.slug)
    assert_response :success
    assert_match available_product.name, response.body
    assert_no_match inactive_product.name, response.body
  end
end
