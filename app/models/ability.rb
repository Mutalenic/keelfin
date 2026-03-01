class Ability
  include CanCan::Ability

  def initialize(user)
    # Guest users have no permissions
    return if user.blank?

    # Regular users can manage their own resources
    can :manage, Category, user_id: user.id
    can :manage, Payment, user_id: user.id
    can :manage, Budget, user_id: user.id
    can :manage, Debt, user_id: user.id
    can :manage, FinancialGoal, user_id: user.id
    can :manage, Investment, user_id: user.id
    can :manage, InvestmentTransaction, user_id: user.id
    can :manage, RecurringTransaction, user_id: user.id
    can :manage, Subscription, user_id: user.id

    # Admin users can manage everything
    can :manage, :all if user.admin?
  end
end
