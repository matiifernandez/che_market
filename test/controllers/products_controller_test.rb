require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @product = products(:one)
  end

  test "should get index" do
    get products_url
    assert_response :success
  end

  test "should get show for active product" do
    get product_url(@product)
    assert_response :success
  end

  test "should return 404 for inactive product" do
    @inactive_product = products(:inactive)
    get product_url(@inactive_product)
    assert_response :not_found
  end

  test "should not include inactive products in index" do
    get products_url
    assert_response :success
    assert_no_match products(:inactive).name, response.body
    assert_match products(:one).name, response.body
  end
end
