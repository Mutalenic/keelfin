module Api
  module V1
    # All API controllers inherit from this base. It:
    #   - Uses ActionController::API (no view layer, faster)
    #   - Requires JWT authentication on every action
    #   - Provides consistent error responses
    #   - Tags structured log lines with request_id and user_id (for lograge)
    class BaseController < ActionController::API
      include Devise::Controllers::Helpers

      before_action :authenticate_user!
      around_action :tag_logs

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable
      rescue_from ActionController::ParameterMissing, with: :bad_request
      rescue_from Ledger::TransactionProcessor::ImbalancedEntries, with: :unprocessable
      rescue_from Ledger::TransactionProcessor::InsufficientFunds, with: :unprocessable

      private

      # Feeds user_id and request_id into lograge's custom_options payload.
      def append_info_to_payload(payload)
        super
        payload[:user_id] = current_user&.id
        payload[:request_id] = request.uuid
      end

      def tag_logs(&)
        user_tag = current_user ? "user_id=#{current_user.id}" : 'unauthenticated'
        Rails.logger.tagged("request_id=#{request.uuid}", user_tag, &)
      end

      def not_found(err)
        render json: { error: err.message }, status: :not_found
      end

      def unprocessable(err)
        render json: { error: err.message }, status: :unprocessable_content
      end

      def bad_request(err)
        render json: { error: err.message }, status: :bad_request
      end
    end
  end
end
