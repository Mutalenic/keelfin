module Admin
  class BnnbDatasController < BaseController
    before_action :set_bnnb_data, only: [:show, :edit, :update, :destroy]

    def index
      @bnnb_datas = BnnbData.order(month: :desc)
    end

    def show; end

    def new
      @bnnb_data = BnnbData.new
    end

    def create
      @bnnb_data = BnnbData.new(bnnb_data_params)
      if @bnnb_data.save
        redirect_to admin_bnnb_datas_path, notice: 'BNNB data created successfully.'
      else
        render :new
      end
    end

    def edit; end

    def update
      if @bnnb_data.update(bnnb_data_params)
        redirect_to admin_bnnb_data_path(@bnnb_data), notice: 'BNNB data updated successfully.'
      else
        render :edit
      end
    end

    def destroy
      @bnnb_data.destroy
      redirect_to admin_bnnb_datas_path, notice: 'BNNB data deleted.'
    end

    private

    def set_bnnb_data
      @bnnb_data = BnnbData.find(params[:id])
    end

    def bnnb_data_params
      params.require(:bnnb_data).permit(:month, :location, :total_basket, :food_basket, :non_food_basket)
    end
  end
end
