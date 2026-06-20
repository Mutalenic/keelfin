module Ledger
  # WebhookDispatcher delivers signed event notifications to all active webhook
  # endpoints registered by the transaction's owner. Each delivery attempt is
  # recorded in WebhookDelivery for auditability and retry tracking.
  #
  # HTTP transport: Faraday with faraday-retry for automatic exponential backoff
  # on transient server errors. HMAC-SHA256 signatures allow receivers to verify
  # authenticity without sharing a password.
  class WebhookDispatcher
    TIMEOUT_SECONDS = 10
    OPEN_TIMEOUT_SECONDS = 5

    def self.call(ledger_transaction)
      new(ledger_transaction).call
    end

    def initialize(ledger_transaction)
      @txn = ledger_transaction
    end

    def call
      endpoints = Ledger::WebhookEndpoint.where(user: @txn.user, active: true)
      endpoints.each { |endpoint| deliver_to(endpoint) }
    end

    private

    def deliver_to(endpoint)
      payload = build_payload
      payload_json = payload.to_json
      signature = generate_signature(endpoint.secret, payload_json)

      delivery = Ledger::WebhookDelivery.create!(
        webhook_endpoint: endpoint,
        ledger_transaction: @txn,
        event_type: 'transaction.posted',
        payload: payload,
        status: 'pending'
      )

      delivery.update!(
        attempt_count: delivery.attempt_count + 1,
        last_attempted_at: Time.current
      )

      response = http_client.post(endpoint.url) do |req|
        req.body = payload_json
        req.headers['Content-Type'] = 'application/json'
        req.headers['X-Keelfine-Signature'] = "sha256=#{signature}"
        req.headers['X-Keelfine-Event'] = 'transaction.posted'
        req.headers['X-Keelfine-Delivery-Id'] = delivery.id.to_s
      end

      delivery.update!(
        status: 'delivered',
        http_status_code: response.status,
        response_body: response.body.to_s.truncate(2000)
      )
    rescue Faraday::Error => e
      delivery&.update!(
        status: 'failed',
        response_body: "#{e.class}: #{e.message}".truncate(2000),
        http_status_code: e.try(:response_status)
      )
    rescue StandardError => e
      delivery&.update!(status: 'failed', response_body: "#{e.class}: #{e.message}".truncate(2000))
    end

    def build_payload
      {
        event: 'transaction.posted',
        transaction_id: @txn.id,
        description: @txn.description,
        status: @txn.status,
        timestamp: @txn.updated_at.iso8601,
        entries: @txn.entries.map do |e|
          {
            account_id: e.account_id,
            direction: e.direction,
            amount_ngwee: e.amount_ngwee,
            currency: e.currency
          }
        end
      }
    end

    def generate_signature(secret, payload_json)
      OpenSSL::HMAC.hexdigest('SHA256', secret, payload_json)
    end

    def http_client
      @http_client ||= Faraday.new do |f|
        f.request :retry,
                  max: 3,
                  interval: 1,
                  backoff_factor: 2,
                  retry_statuses: [429, 500, 502, 503, 504],
                  methods: %i[post]
        f.options.timeout = TIMEOUT_SECONDS
        f.options.open_timeout = OPEN_TIMEOUT_SECONDS
        f.adapter Faraday.default_adapter
      end
    end
  end
end
