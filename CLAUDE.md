# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Che Market is a Rails 7.1 e-commerce platform for Argentine products (yerba mate, dulce de leche, alfajores). It supports both guest and authenticated shopping with international shipping.

## Common Commands

```bash
# Start development server (runs Rails + Tailwind CSS watcher)
bin/dev

# Database setup
rails db:create db:migrate db:seed

# Run all tests
rails test

# Run a single test file
rails test test/models/product_test.rb

# Run a specific test by line number
rails test test/models/product_test.rb:10

# Rails console
rails console

# View development emails (after starting server)
# Navigate to: http://localhost:3000/letter_opener
```

## Architecture

### Authentication & Authorization
- **Devise** for user authentication
- **Pundit** for authorization (policies in `app/policies/`)
- User roles: `customer` (default) and `admin` (enum in User model)
- Admin access enforced via `Admin::BaseController` which requires `admin?` role

### Cart System
- `CartManagement` concern (`app/controllers/concerns/cart_management.rb`) provides `current_cart` helper
- Carts use `secret_id` for guest identification via session
- Guest carts automatically merge into user cart on login (`transfer_cart_to_user`)

### Payments
- **Stripe Checkout** for payments (redirect-based flow)
- Checkout flow: `CheckoutsController#create` builds Stripe session, redirects to Stripe
- Success callback creates Order and sends confirmation email
- Webhook endpoint at `/webhooks/stripe` (webhooks_controller.rb)

### Money Handling
- **money-rails** gem with USD as default currency
- Prices stored as `_cents` columns (e.g., `price_cents`, `total_cents`)
- Use `monetize :price_cents` in models

### Image Uploads
- **Active Storage** with **Cloudinary** for production
- Products have `has_many_attached :images`
- Rich text descriptions via **Action Text** (`has_rich_text :description`)

### Admin Panel
- Namespaced under `/admin` with separate layout (`app/views/layouts/admin.html.erb`)
- All admin controllers inherit from `Admin::BaseController`
- Manages products, categories, and orders

### Frontend
- **Tailwind CSS** for styling
- **Hotwire** (Turbo + Stimulus) for JavaScript
- Stimulus controllers in `app/javascript/controllers/`

## Key Models

- **Product**: `monetize :price_cents`, scopes `active`, `in_stock`, `available`
- **Order**: statuses `pending`, `paid`, `shipped`, `delivered`, `cancelled`
- **Cart**: belongs to user (optional), has many cart_items
- **User**: Devise auth, `role` enum (customer/admin), has_one cart

## Environment Variables

Required in `.env` (see `.env.example`):
- `STRIPE_PUBLISHABLE_KEY`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`
- `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`

## Testing

Uses Rails default Minitest framework. Test files in `test/` directory.
