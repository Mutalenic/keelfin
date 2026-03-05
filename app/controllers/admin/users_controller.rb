module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[show edit update toggle_admin impersonate]

    def index
      @users = User.order(created_at: :desc)
      if params[:q].present?
        @users = @users.where('name ILIKE ? OR email ILIKE ?', "%#{params[:q]}%",
                              "%#{params[:q]}%")
      end
      @users = @users.where(role: params[:role]) if params[:role].present?
    end

    def show
      @payments = @user.payments.includes(:category).order(created_at: :desc).limit(20)
      @categories = @user.categories
      @budgets = @user.budgets.includes(:category)
      @debts = @user.debts
      @goals = @user.financial_goals
      @investments = @user.investments
    end

    def edit; end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: 'User updated successfully.'
      else
        render :edit
      end
    end

    def toggle_admin
      new_role = @user.admin? ? 'default' : 'admin'
      @user.update(role: new_role)
      redirect_to admin_user_path(@user), notice: "User role changed to #{new_role}."
    end

    def impersonate
      sign_in(:user, @user)
      redirect_to root_path, notice: "Now impersonating #{@user.name}."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:name, :email, :monthly_income, :phone_number, :currency)
    end
  end
end
