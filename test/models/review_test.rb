require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @product = products(:one)
  end

  test "allows pending to approved transition" do
    review = Review.create!(
      user: @user,
      product: @product,
      rating: 5,
      body: "Muy buen producto, lo recomiendo totalmente.",
      status: :pending
    )

    assert review.update(status: :approved)
  end

  test "blocks changing status after approval" do
    review = Review.create!(
      user: @user,
      product: @product,
      rating: 5,
      body: "Excelente calidad, volveria a comprar.",
      status: :approved
    )

    assert_not review.update(status: :rejected)
    assert review.errors[:status].any?
  end
end
