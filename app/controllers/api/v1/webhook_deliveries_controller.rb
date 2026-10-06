module Api
  module V1
    class WebhookDeliveriesController < BaseController
      ENTRIES_PER_PAGE = 25

      def index
        page = [params.fetch(:page, 1).to_i, 1].max
        per_page = [params.fetch(:per, ENTRIES_PER_PAGE).to_i, 100].min
        offset = (page - 1) * per_page

        deliveries = Ledger::WebhookDelivery
          .joins(:webhook_endpoint)
          .where(ledger_webhook_endpoints: { user: current_user })
          .order(created_at: :desc)
          .limit(per_page)
          .offset(offset)

        render json: {
          page: page,
          per: per_page,
          webhook_deliveries: deliveries.map { |d| serialize_delivery(d) }
        }
      end

      private

      def serialize_delivery(delivery)
        {
          id: delivery.id,
          event_type: delivery.event_type,
          status: delivery.status,
          http_status_code: delivery.http_status_code,
          attempt_count: delivery.attempt_count,
          last_attempted_at: delivery.last_attempted_at&.iso8601,
          transaction_id: delivery.transaction_id,
          created_at: delivery.created_at.iso8601
        }
      end
    end
  end
end
