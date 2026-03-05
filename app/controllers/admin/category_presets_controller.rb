module Admin
  class CategoryPresetsController < BaseController
    before_action :set_preset, only: [:show, :edit, :update, :destroy]

    def index
      @presets = CategoryPreset.ordered
      @presets = @presets.by_type(params[:type]) if params[:type].present?
    end

    def show; end

    def new
      @preset = CategoryPreset.new
    end

    def create
      @preset = CategoryPreset.new(preset_params)
      if @preset.save
        redirect_to admin_category_presets_path, notice: 'Category preset created successfully.'
      else
        render :new
      end
    end

    def edit; end

    def update
      if @preset.update(preset_params)
        redirect_to admin_category_preset_path(@preset), notice: 'Category preset updated successfully.'
      else
        render :edit
      end
    end

    def destroy
      @preset.destroy
      redirect_to admin_category_presets_path, notice: 'Category preset deleted.'
    end

    private

    def set_preset
      @preset = CategoryPreset.find(params[:id])
    end

    def preset_params
      params.require(:category_preset).permit(:name, :icon, :icon_name, :color, :category_type, :description, :is_default, :display_order)
    end
  end
end
