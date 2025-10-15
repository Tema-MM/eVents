# config/initializers/stripe.rb
Stripe.api_key = ENV.fetch("STRIPE_SECRET_KEY", nil)
Stripe.api_version = "2024-06-20"
