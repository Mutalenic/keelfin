module Keelfin
  # Custom Warden failure app for Devise. Routes under /api/ receive JSON 401
  # responses instead of the standard HTML redirect to the sign-in page.
  class ApiFailureApp < Devise::FailureApp
    def respond
      if api_request?
        json_api_error_response
      else
        super
      end
    end

    private

    def api_request?
      request.path.starts_with?('/api/')
    end

    def json_api_error_response
      self.status = 401
      self.content_type = 'application/json'
      self.response_body = {
        error: i18n_message,
        message: 'Authentication required. Please provide a valid JWT token.'
      }.to_json
    end
  end
end
