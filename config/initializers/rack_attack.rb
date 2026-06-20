# API rate limiting via Rack::Attack.
# Limits are conservative; adjust per production traffic patterns.
Rack::Attack.throttle('api/sign_in', limit: 5, period: 1.minute) do |req|
  req.ip if req.path == '/api/v1/auth/sign_in' && req.post?
end

Rack::Attack.throttle('api/general', limit: 100, period: 1.minute) do |req|
  req.ip if req.path.start_with?('/api/')
end

# Return a JSON 429 instead of the default plain-text response.
Rack::Attack.throttled_responder = lambda do |_env|
  [
    429,
    { 'Content-Type' => 'application/json' },
    [{ error: 'Too many requests. Please try again later.' }.to_json]
  ]
end
