require "test_helper"

class PaginationPartialTest < ActionView::TestCase
  test "renders pagination with pagy page_url" do
    request = ActionDispatch::TestRequest.create("GET", "/products?page=2")
    pagy = Pagy::Offset.new(count: 30, page: 2, limit: 10, request: request)

    html = render(partial: "shared/pagination", locals: { pagy: pagy })

    assert_includes html, "page=1"
    assert_includes html, "page=3"
  end
end
