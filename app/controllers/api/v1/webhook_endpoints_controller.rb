module Api
  module V1
    class WebhookEndpointsController < BaseController
      def index
        endpoints = current_user.ledger_webhook_endpoints.order(created_at: :desc)
        render json: endpoints.map { |e| serialize_endpoint(e) }
      end

      def create
        endpoint = current_user.ledger_webhook_endpoints.create!(endpoint_params)
        render json: serialize_endpoint(endpoint), status: :created
      end

      def destroy
        endpoint = current_user.ledger_webhook_endpoints.find(params[:id])
        endpoint.update!(active: false)
        head :no_content
      end

      private

      def endpoint_params
        params.require(:webhook_endpoint).permit(:url, event_types: [])
      end

      def serialize_endpoint(endpoint)
        {
          id: endpoint.id,
          url: endpoint.url,
          active: endpoint.active,
          event_types: endpoint.event_types,
          # Expose only first/last 4 chars of secret so client can verify their copy
          secret_hint: "#{endpoint.secret[0, 4]}...#{endpoint.secret[-4, 4]}",
          created_at: endpoint.created_at.iso8601
        }
      end
    end
  end
end
