module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[show edit update toggle_admin impersonate]
    before_action :ensure_not_already_impersonating, only: :impersonate

    def index
      users = User.order(created_at: :desc)
      if params[:q].present?
        users = users.where('name ILIKE ? OR email ILIKE ?', "%#{params[:q]}%",
                            "%#{params[:q]}%")
      end
      users = users.where(role: params[:role]) if params[:role].present?
      @pagy, @users = pagy(users)
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
      session[:impersonating_admin_id] = current_user.id
      Rails.logger.warn "[IMPERSONATE] Admin ##{current_user.id} (#{current_user.email}) " \
                        "impersonating User ##{@user.id} (#{@user.email}) " \
                        "at #{Time.current.iso8601} from #{request.remote_ip}"
      sign_in(:user, @user)
      redirect_to root_path, notice: "Now impersonating #{@user.name}. " \
                                     'Use the Stop Impersonating button to return.'
    end

    def stop_impersonating
      admin_id = session.delete(:impersonating_admin_id)
      admin = User.find_by(id: admin_id)
      if admin
        sign_in(:user, admin)
        redirect_to admin_root_path, notice: 'Stopped impersonating. Welcome back.'
      else
        sign_out
        redirect_to new_user_session_path, alert: 'Session expired. Please log in again.'
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def ensure_not_already_impersonating
      return if session[:impersonating_admin_id].blank?

      redirect_to admin_root_path, alert: 'You are already impersonating a user.'
    end

    def user_params
      params.require(:user).permit(:name, :email, :monthly_income, :phone_number, :currency)
    end
  end
end
