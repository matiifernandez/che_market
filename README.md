# Che Market 🧉

E-commerce platform for Argentine products worldwide. Yerba mate, dulce de leche, alfajores and more, delivered to your door.

## Demo

[Production link coming soon]

## Features

- **Product catalog** with categories, filters and real-time search
- **Shopping cart** for registered users and guests
- **Stripe Checkout** with webhook integration for secure payments
- **International shipping** to 100+ countries
- **Admin panel** to manage products, categories and orders
- **Order notifications** - Confirmation, shipped and admin alerts
- **Email verification** for new user accounts
- **Cloudinary** for optimized image uploads

## Tech Stack

| Technology     | Purpose        |
| -------------- | -------------- |
| Ruby 3.3.5     | Language       |
| Rails 7.1.6    | Framework      |
| PostgreSQL     | Database       |
| Tailwind CSS   | Styling        |
| Hotwire        | Turbo + Stimulus |
| Devise         | Authentication |
| Pundit         | Authorization  |
| Stripe         | Payments       |
| Cloudinary     | Image CDN      |
| Money-rails    | Price handling |
| Simple Form    | Forms          |
| Action Text    | Rich text      |

## Installation

### Prerequisites

- Ruby 3.3.5
- Rails 7.1.6
- PostgreSQL
- Node.js (for Tailwind)

### Setup

```bash
# Clone the repository
git clone https://github.com/matiifernandez/che_market.git
cd che_market

# Install dependencies
bundle install

# Setup database
rails db:create
rails db:migrate
rails db:seed

# Configure environment variables
cp .env.example .env
# Edit .env with your API keys

# Start the server
bin/dev
```

### Environment Variables

Create a `.env` file with:

```
STRIPE_PUBLISHABLE_KEY=pk_test_xxx
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

CLOUDINARY_CLOUD_NAME=xxx
CLOUDINARY_API_KEY=xxx
CLOUDINARY_API_SECRET=xxx
```

## Usage

### Admin User

After running `rails db:seed`:

- **Email:** admin@chemarket.com
- **Password:** password123

### Test Card (Stripe)

- **Number:** 4242 4242 4242 4242
- **Expiry:** Any future date
- **CVC:** Any 3 digits

## Screenshots

[Screenshots coming soon]

## Roadmap

- [x] Product catalog with real-time search
- [x] Shopping cart
- [x] Stripe Checkout with webhooks
- [x] Admin panel with new order indicators
- [x] Email notifications (confirmation, shipped, admin)
- [x] Cloudinary image uploads
- [x] Email verification
- [ ] Multi-currency support
- [ ] Shipping cost calculator
- [ ] Promo codes and discounts
- [ ] Production deployment

## Author

**Mati Fernandez**

- GitHub: [@matiifernandez](https://github.com/matiifernandez)

## License

This project is licensed under the MIT License.
