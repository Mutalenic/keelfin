class ComingSoonController < ApplicationController
  before_action :authenticate_user!

  def index
    @feature_name = params[:feature] || 'This feature'
    @premium_only = params[:premium] == 'true'
  end
end
