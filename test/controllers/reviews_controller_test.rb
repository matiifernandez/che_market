require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @product = products(:one)
    @review = Review.create!(
      user: users(:two),
      product: @product,
      rating: 5,
      title: "Excelente",
      body: "Muy buen producto, lo recomiendo totalmente.",
      status: :approved,
      helpful_count: 0
    )
  end

  test "marks review as helpful only once per user" do
    sign_in @user

    assert_difference("ReviewHelpfulVote.count", 1) do
      post helpful_product_review_path(@product, @review)
    end
    assert_redirected_to product_path(@product, anchor: "reviews")
    assert_equal 1, @review.reload.helpful_count

    assert_no_difference("ReviewHelpfulVote.count") do
      post helpful_product_review_path(@product, @review)
    end
    assert_redirected_to product_path(@product, anchor: "reviews")
    assert_equal 1, @review.reload.helpful_count
  end
end
