# Copilot Instructions

Che Market is a Rails 7.1 e-commerce platform for Argentine products (yerba mate, dulce de leche, alfajores), supporting guest and authenticated shopping with international shipping.

## Commands

```bash
bin/dev                                          # Start server + Tailwind watcher
rails test                                       # Run all tests
rails test test/models/product_test.rb           # Run a single test file
rails test test/models/product_test.rb:10        # Run a specific test by line
rails db:create db:migrate db:seed               # Database setup
rails console
# http://localhost:3000/letter_opener            # Preview dev emails
```

## Architecture

### Localization
Default locale is **Spanish** (`:es`). Strings live in `config/locales/es.yml` and `en.yml`. Always use `I18n.t(...)` for user-facing strings. The locale is stored in session and set via `ApplicationController#set_locale`.

### Money
All prices are stored as integer cent columns (e.g. `price_cents`, `total_cents`). Use `monetize :price_cents` in models. Currency is USD. Never do arithmetic on `Money` objects directly — use `_cents` integer methods for calculations, then wrap in `Money.new(cents, "USD")` when needed.

### Cart System
`CartManagement` concern (included in `ApplicationController`) exposes `current_cart`. Carts are identified by `secret_id` stored in session — this enables guest carts. On login, `transfer_cart_to_user` (called via `after_action`) merges the guest cart into the user's cart. Cart total = subtotal − coupon discount − gift card credit.

### Payments (Stripe)
`CheckoutsController#create` builds a Stripe Checkout Session and redirects to Stripe. On return, `#success` handles order creation. Orders can also be created by the webhook at `/webhooks/stripe`. Both paths use `stripe_session_id` uniqueness to prevent duplicates; race conditions are caught with `ActiveRecord::RecordNotUnique`.

When the cart total is zero (gift card covers everything), `CheckoutsController` skips Stripe entirely and calls `create_order_paid_with_gift_card`.

Coupon + gift card discounts are combined into a single one-time Stripe coupon when building the session.

### Authorization
- **Devise** handles authentication (`:confirmable` is enabled — new users must confirm email).
- **Pundit** policies live in `app/policies/`.
- `Admin::BaseController` enforces `current_user.admin?` for all admin routes; redirects to root on failure.
- User roles are an enum: `customer: 0, admin: 1`.

### Admin Panel
All admin controllers are under `app/controllers/admin/` and inherit from `Admin::BaseController`, which uses the `admin` layout. Routes are namespaced under `/admin`.

### Background Jobs
Uses **Solid Queue** (database-backed). Jobs are dispatched with `deliver_later` (mailers). No separate worker process is needed in development beyond `bin/dev`.

### Pagination
Include `Pagy::Backend` in controllers and `Pagy::Frontend` in helpers. Use `pagy(scope)` to paginate, `pagy_nav(@pagy)` in views.

## Key Conventions

- **Scopes on Product**: `active`, `in_stock`, `available` (= `active.in_stock`). Always use `available` for storefront queries.
- **Coupon codes** are normalized to uppercase on save (`before_validation :normalize_code`). Look them up with `UPPER(code) = ?`.
- **Gift card amounts** are fixed: `[2000, 5000, 10000]` cents ($20/$50/$100). Validate with `GiftCard.valid_amount?(cents)`.
- **Order creation** always: creates `LineItem` records, decrements `product.stock`, increments `coupon.uses_count`, applies gift card balance, and enqueues `OrderMailer.confirmation` + `OrderMailer.admin_notification`.
- **Forms** use `simple_form`. Admin views use the `admin` layout; public views use `application`.
- **Images** use Active Storage + Cloudinary in production. Products use `has_many_attached :images`. Rich text descriptions via `has_rich_text :description`.
- **Stimulus controllers** are in `app/javascript/controllers/` and follow the standard `*_controller.js` naming.

## Environment Variables

See `.env.example`. Required:
- `STRIPE_PUBLISHABLE_KEY`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`
- `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`
