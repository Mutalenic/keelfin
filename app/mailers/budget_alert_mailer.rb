class BudgetAlertMailer < ApplicationMailer
  def near_limit(user, budget_data)
    @user = user
    @budget_data = budget_data
    @near_limit = budget_data.select { |b| b[:pct] >= 80 && b[:pct] < 100 }
    @overspent = budget_data.select { |b| b[:pct] >= 100 }
    mail(
      to: user.email,
      subject: "⚠️ Budget alert — #{overspent_or_near(budget_data)}"
    )
  end

  private

  def overspent_or_near(budget_data)
    overspent = budget_data.count { |b| b[:pct] >= 100 }
    near = budget_data.count { |b| b[:pct] >= 80 && b[:pct] < 100 }
    parts = []
    parts << "#{overspent} budget#{'s' if overspent > 1} exceeded" if overspent > 0
    parts << "#{near} budget#{'s' if near > 1} near limit" if near > 0
    parts.join(', ')
  end
end
