#!/bin/bash

# Quick deploy script for local use
# This will copy your app to the server

echo "🚀 Deploying Digi Budget to DigitalOcean..."

# Copy your app to server
rsync -avz --exclude='.git' --exclude='log' --exclude='tmp' \
  --exclude='node_modules' \
  ./ deploy@144.126.239.114:~/digi_budget/

echo "✅ Files copied to server!"
echo ""
echo "📝 Next steps on server:"
echo "1. SSH into server: ssh deploy@144.126.239.114"
echo "2. Run: cd ~/digi_budget"
echo "3. Run: PATH=\"$HOME/.rbenv/bin:$PATH\" ~/.rbenv/shims/bundle install"
echo "4. Run: export RAILS_ENV=production"
echo "5. Run: export DATABASE_URL=\"postgresql://deploy@localhost/digi_budget_production\""
echo "6. Run: PATH=\"$HOME/.rbenv/bin:$PATH\" ~/.rbenv/shims/rake db:migrate"
echo "7. Run: PATH=\"$HOME/.rbenv/bin:$PATH\" ~/.rbenv/shims/rake assets:precompile"
echo "8. Run: PATH=\"$HOME/.rbenv/bin:$PATH\" ~/.rbenv/shims/puma -C config/puma.rb -e production"
