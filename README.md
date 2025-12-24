# Che Market

E-commerce template for Argentine products. Built with Rails 7.1, ready to customize and deploy.

## Demo

[Production link coming soon]

## Features

### Shopping Experience
- **Product catalog** with categories, search, and pagination
- **Shopping cart** for guests and registered users (auto-merge on login)
- **Wishlist** to save favorite products
- **Reviews & ratings** with verified purchase badges and moderation
- **Multi-language** support (Spanish/English)

### Payments & Discounts
- **Stripe Checkout** with webhook integration
- **Coupon system** - percentage or fixed discounts, expiration dates, usage limits
- **Gift cards** - $20/$50/$100, email delivery, partial balance usage
- **International shipping** to 160+ countries

### Customer Account
- **Order history** with status tracking
- **Shipment tracking** with carrier info
- **Profile management** and password reset
- **Email notifications** - order confirmation, shipping updates

### Admin Panel
- **Dashboard** with stats, revenue, low stock alerts
- **Product management** with multiple images and rich text
- **Order management** with status updates and tracking
- **Coupon management** with analytics
- **Gift card management** with transaction history
- **Review moderation** workflow

### Technical
- **Background jobs** with Solid Queue (database-backed)
- **Email system** configured for any SMTP provider
- **SEO** with sitemap generation
- **Cloudinary** for optimized image delivery

## Tech Stack

| Technology | Purpose |
|------------|---------|
| Ruby 3.3.5 | Language |
| Rails 7.1 | Framework |
| PostgreSQL | Database |
| Tailwind CSS | Styling |
| Hotwire | Turbo + Stimulus |
| Devise | Authentication |
| Pundit | Authorization |
| Stripe | Payments |
| Solid Queue | Background jobs |
| Cloudinary | Image CDN |
| Money-rails | Price handling |

## Quick Start

### Prerequisites

- Ruby 3.3.5
- PostgreSQL
- Node.js (for Tailwind)
- Stripe account (for payments)
- Cloudinary account (for images)

### Installation

```bash
# Clone
git clone https://github.com/matiifernandez/che_market.git
cd che_market

# Install dependencies
bundle install

# Setup database
rails db:create db:migrate db:seed

# Configure environment
cp .env.example .env
# Edit .env with your API keys

# Start server
bin/dev
```

### Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Required
STRIPE_PUBLISHABLE_KEY=pk_test_xxx
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
CLOUDINARY_CLOUD_NAME=xxx
CLOUDINARY_API_KEY=xxx
CLOUDINARY_API_SECRET=xxx

# Email
ADMIN_EMAIL=admin@yourdomain.com
CONTACT_EMAIL=support@yourdomain.com
MAILER_FROM_EMAIL=noreply@yourdomain.com
MAILER_FROM_NAME=Your Store Name

# SMTP (production)
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=your_api_key
```

See `.env.example` for all available options.

## Usage

### Default Admin

After `rails db:seed`:
- **Email:** admin@chemarket.com
- **Password:** password123

### Stripe Test Card

- **Number:** 4242 4242 4242 4242
- **Expiry:** Any future date
- **CVC:** Any 3 digits

### Stripe Webhooks (Development)

```bash
# Install Stripe CLI, then:
stripe listen --forward-to localhost:3000/webhooks/stripe
```

### Background Jobs

Development uses async processing (no worker needed). For production:

```bash
bundle exec rake solid_queue:start
```

Or use the included `Procfile` with your platform.

## Customization

This is a template. To customize:

1. **Branding** - Update `MAILER_FROM_NAME`, logos, colors in Tailwind
2. **Products** - Modify seed data or use admin panel
3. **Shipping** - Edit countries in `CheckoutsController#shipping_countries`
4. **Emails** - Customize templates in `app/views/*_mailer/`
5. **Translations** - Edit `config/locales/*.yml`

## Testing

```bash
# Run all tests
rails test

# Run specific file
rails test test/controllers/checkouts_controller_test.rb
```

## Deployment

The app is ready for deployment on platforms like Heroku, Render, or Railway.

Required:
- PostgreSQL database
- Environment variables configured
- Stripe webhook endpoint set to `https://yourdomain.com/webhooks/stripe`

## Author

**Mati Fernandez** - [matiasfernandez.me](https://www.matiasfernandez.me) - [@matiifernandez](https://github.com/matiifernandez)

## License

MIT License - Use it, modify it, ship it.
