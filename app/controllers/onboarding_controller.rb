class OnboardingController < ApplicationController
  before_action :authenticate_user!

  def show
    @step = determine_step
    @category_presets = CategoryPreset.ordered if @step == :categories
  end

  def update
    case params[:step]
    when 'income'
      current_user.update(monthly_income: params[:monthly_income])
      redirect_to onboarding_path(step: 'categories')
    when 'categories'
      create_categories_from_presets
      redirect_to onboarding_path(step: 'budget')
    when 'budget'
      create_initial_budgets
      redirect_to onboarding_complete_path
    else
      redirect_to onboarding_path
    end
  end

  def complete
    current_user.ensure_subscription
  end

  private

  def determine_step
    return :income if current_user.monthly_income.blank?
    return :categories if current_user.categories.count < 3
    return :budget if current_user.budgets.empty?

    :complete
  end

  def create_categories_from_presets
    preset_ids = params[:preset_ids] || []
    preset_ids.each do |id|
      preset = CategoryPreset.find_by(id: id)
      next unless preset
      next if current_user.categories.exists?(name: preset.name)

      current_user.categories.create(preset.to_category_params)
    end
  end

  def create_initial_budgets
    budget_params = params[:budgets] || {}
    budget_params.each do |category_id, amount|
      next if amount.blank? || amount.to_f <= 0

      category = current_user.categories.find_by(id: category_id)
      next unless category

      current_user.budgets.find_or_create_by(category: category) do |budget|
        budget.monthly_limit = amount.to_f
        budget.start_date = Date.current.beginning_of_month
        budget.end_date = Date.current.end_of_month
      end
    end
  end
end
