module Admin
  class EconomicIndicatorsController < BaseController
    before_action :set_indicator, only: [:show, :edit, :update, :destroy]

    def index
      @indicators = EconomicIndicator.order(date: :desc)
    end

    def show; end

    def new
      @indicator = EconomicIndicator.new
    end

    def create
      @indicator = EconomicIndicator.new(indicator_params)
      if @indicator.save
        redirect_to admin_economic_indicators_path, notice: 'Economic indicator created successfully.'
      else
        render :new
      end
    end

    def edit; end

    def update
      if @indicator.update(indicator_params)
        redirect_to admin_economic_indicator_path(@indicator), notice: 'Economic indicator updated successfully.'
      else
        render :edit
      end
    end

    def destroy
      @indicator.destroy
      redirect_to admin_economic_indicators_path, notice: 'Economic indicator deleted.'
    end

    private

    def set_indicator
      @indicator = EconomicIndicator.find(params[:id])
    end

    def indicator_params
      params.require(:economic_indicator).permit(:date, :inflation_rate, :usd_zmw_rate, :source)
    end
  end
end
