class Users::RegistrationsController < Devise::RegistrationsController
  layout :resolve_layout

  private

  def resolve_layout
    action_name == 'edit' ? 'application' : 'auth'
  end

  public

  protected

  def after_sign_up_path_for(_resource)
    onboarding_path
  end

  def after_inactive_sign_up_path_for(_resource)
    new_user_session_path
  end
end
