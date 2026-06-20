module Api
  module V1
    # Handles JWT sign-in and sign-out.
    # devise-jwt automatically appends the JWT to the Authorization response
    # header on sign_in and revokes it (changes jti) on sign_out.
    # We override respond_with to include user data alongside the header token.
    class SessionsController < Devise::SessionsController
      respond_to :json

      # ApplicationController requires authentication globally, but the API
      # sign-in/sign-out endpoints must be public so users can obtain a JWT.
      def authenticate_user!
        return if action_name.in?(%w[new create destroy])

        super
      end

      private

      def respond_with(resource, _opts = {})
        render json: {
          message: 'Logged in successfully.',
          user: {
            id: resource.id,
            name: resource.name,
            email: resource.email
          }
        }, status: :ok
      end

      def respond_to_on_destroy
        head :no_content
      end
    end
  end
end
