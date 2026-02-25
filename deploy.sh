#!/bin/bash

# Digi Budget Deployment Script
# Run this on your server: ssh deploy@144.126.239.114

# Set environment variables
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

echo "🚀 Starting Digi Budget Deployment..."

# Clone your app (replace with your repo URL)
cd ~
if [ ! -d "digi_budget" ]; then
    echo "📥 Cloning repository..."
    # You'll need to replace this with your actual repo
    git clone https://github.com/YOUR_USERNAME/digi_budget.git
fi

cd digi_budget

echo "💎 Installing Ruby gems..."
PATH="$HOME/.rbenv/bin:$PATH" ~/.rbenv/shims/bundle install --deployment --without development test

echo "🗄️ Setting up database..."
export RAILS_ENV=production
export DATABASE_URL="postgresql://deploy@localhost/digi_budget_production"

# Create database if it doesn't exist
PATH="$HOME/.rbenv/bin:$PATH" ~/.rbenv/shims/rake db:create

# Run migrations
PATH="$HOME/.rbenv/bin:$PATH" ~/.rbenv/shims/rake db:migrate

# Precompile assets
echo "🎨 Precompiling assets..."
PATH="$HOME/.rbenv/bin:$PATH" ~/.rbenv/shims/rake assets:precompile

echo "🔥 Starting Puma server..."
# Start Puma in production mode
PATH="$HOME/.rbenv/bin:$PATH" ~/.rbenv/shims/puma -C config/puma.rb -e production
