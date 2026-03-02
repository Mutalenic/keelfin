module Admin
  class BaseController < ApplicationController
    before_action :require_admin!
    layout 'admin'

    private

    def require_admin!
      return if current_user&.admin?

      redirect_to root_path, alert: 'You are not authorized to access the admin area.'
    end
  end
end
