# Che Market 🧉

E-commerce platform for Argentine products worldwide. Yerba mate, dulce de leche, alfajores and more, delivered to your door.

## Demo

[Production link coming soon]

## Features

- **Product catalog** with categories and filters
- **Shopping cart** for registered users and guests
- **Stripe Checkout** - Secure card payments
- **International shipping** to 100+ countries
- **Admin panel** to manage products, categories and orders
- **Confirmation emails** sent automatically after purchase

## Tech Stack

| Technology     | Purpose        |
| -------------- | -------------- |
| Ruby 3.3.5     | Language       |
| Rails 7.1.6    | Framework      |
| PostgreSQL     | Database       |
| Tailwind CSS   | Styling        |
| Stimulus       | JavaScript     |
| Devise         | Authentication |
| Pundit         | Authorization  |
| Stripe         | Payments       |
| Money-rails    | Price handling |
| Simple Form    | Forms          |
| Action Text    | Rich text      |
| Active Storage | Image uploads  |

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

- [x] Product catalog
- [x] Shopping cart
- [x] Stripe Checkout
- [x] Admin panel
- [x] Confirmation emails
- [ ] Cloudinary image uploads
- [ ] Stripe webhooks
- [ ] Heroku deployment
- [ ] Shipping cost calculator
- [ ] Shipping notifications

## Author

**Mati Fernandez**

- GitHub: [@matiifernandez](https://github.com/matiifernandez)

## License

This project is licensed under the MIT License.

```

---
```
