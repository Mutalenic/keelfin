class ApplicationController < ActionController::Base
  protect_from_forgery prepend: true
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Global handler for unauthorized access
  rescue_from CanCan::AccessDenied do |_exception|
    respond_to do |format|
      format.html do
        redirect_back_or_to(root_path, alert: 'You are not authorized to perform this action.')
      end
      format.json { render json: { error: 'Unauthorized' }, status: :forbidden }
    end
  end

  rescue_from ActiveRecord::RecordNotFound do |_exception|
    respond_to do |format|
      format.html { redirect_back_or_to(root_path, alert: 'Record not found.') }
      format.json { render json: { error: 'Not found' }, status: :not_found }
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:name, :email, :password, :monthly_income) }
    devise_parameter_sanitizer.permit(:account_update) do |u|
      u.permit(:name, :email, :password, :current_password, :monthly_income, :phone_number, :currency)
    end
  end

  def layout_by_resource
    if devise_controller?
      'auth'
    else
      'application'
    end
  end

  private

  def current_ability
    @current_ability ||= Ability.new(current_user)
  end
end
