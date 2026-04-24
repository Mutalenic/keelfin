class IncomeSourcesController < ApplicationController
  before_action :set_income_source, only: %i[edit update destroy]

  def index
    @income_sources = current_user.income_sources.order(created_at: :asc)
    @total_monthly = @income_sources.active.sum(&:monthly_equivalent)
  end

  def new
    @income_source = current_user.income_sources.new
  end

  def create
    @income_source = current_user.income_sources.new(income_source_params)

    if @income_source.save
      redirect_to income_sources_path, notice: 'Income source added successfully.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @income_source.update(income_source_params)
      redirect_to income_sources_path, notice: 'Income source updated.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @income_source.destroy
    redirect_to income_sources_path, notice: 'Income source removed.'
  end

  private

  def set_income_source
    @income_source = current_user.income_sources.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to income_sources_path, alert: 'Income source not found.'
  end

  def income_source_params
    params.require(:income_source).permit(:name, :amount, :frequency, :active, :notes)
  end
end
