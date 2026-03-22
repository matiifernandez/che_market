require "test_helper"

class StructuredDataHelperTest < ActionView::TestCase
  include StructuredDataHelper
  fixtures :all

  setup do
    @product = products(:one)
  end

  test "product_json_ld returns valid JSON script tag" do
    result = product_json_ld(@product)
    
    assert_match /script type="application\/ld\+json"/, result
    
    # Parse JSON content from tag
    json_content = result.match(/>(.*)</m)[1]
    data = JSON.parse(json_content)
    
    assert_equal "Product", data["@type"]
    assert_equal @product.name, data["name"]
    assert_equal @product.price.amount.to_s("F"), data["offers"]["price"]
    assert_equal @product.price.currency.iso_code, data["offers"]["priceCurrency"]
  end

  test "product_json_ld includes aggregate rating and reviews for product with reviews" do
    assert @product.reviews_count.positive?, "Expected @product to have reviews in fixtures"

    result = product_json_ld(@product)
    json_content = result.match(/>(.*)</m)[1]
    data = JSON.parse(json_content)
    
    assert data.key?("aggregateRating")
    assert_equal @product.average_rating.to_f, data["aggregateRating"]["ratingValue"].to_f
    assert_equal @product.reviews_count.to_i, data["aggregateRating"]["reviewCount"].to_i
    assert data.key?("review")
    assert_equal @product.visible_reviews.limit(5).count, data["review"].length
  end
end
