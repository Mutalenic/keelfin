# Allow cross-origin requests to the /api/* namespace from the Next.js dashboard
# (both production Vercel URL and local dev server).
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'https://dashboard.keelfine.app',
            'http://localhost:3000',
            'http://localhost:3001'

    resource '/api/*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             expose: ['Authorization']
  end
end
