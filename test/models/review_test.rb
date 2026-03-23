require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @product = products(:two)
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

  test "allows pending to rejected transition" do
    review = Review.create!(
      user: @user,
      product: @product,
      rating: 3,
      body: "No me convencio del todo.",
      status: :pending
    )

    assert review.update(status: :rejected)
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
    assert_includes review.errors.details[:status].map { |e| e[:error] }, :invalid_transition
  end

  test "blocks rejected to approved transition" do
    review = Review.create!(
      user: @user,
      product: @product,
      rating: 2,
      body: "Tuvo varios problemas, no lo recomiendo.",
      status: :rejected
    )

    assert_not review.update(status: :approved)
    assert_includes review.errors.details[:status].map { |e| e[:error] }, :invalid_transition
  end
end
