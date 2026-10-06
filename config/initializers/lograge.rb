# Structured JSON request logging for the API. Each request line becomes a
# single JSON object — easy to query in CloudWatch / any log aggregator.
Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new

  # Merge per-request fields populated by BaseController#append_info_to_payload.
  config.lograge.custom_options = lambda do |event|
    {
      user_id: event.payload[:user_id],
      request_id: event.payload[:request_id] || event.payload[:headers]&.[]('action_dispatch.request_id'),
      time: Time.current.iso8601
    }.compact
  end
end
