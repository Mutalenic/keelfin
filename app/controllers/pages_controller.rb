class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  before_action :set_user, only: %i[show update destroy]

  def index
    @users = User.all
  end
end
