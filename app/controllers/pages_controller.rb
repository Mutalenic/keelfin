class PagesController < ApplicationController
  before_action :require_admin!
  before_action :set_user, only: %i[show update destroy]

  def index
    @users = User.order(:created_at)
  end

  def show; end

  def update; end

  def destroy; end

  private

  def require_admin!
    redirect_to root_path, alert: 'Not authorized.' unless current_user&.admin?
  end
end
