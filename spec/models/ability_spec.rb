require 'rails_helper'

# cancan/matchers uses ActiveSupport::Deprecation which was removed in Rails 7.1.
# Use ability.can? / ability.cannot? directly instead.
RSpec.describe Ability, type: :model do
  subject(:ability) { Ability.new(user) }

  context "when a guest (nil user)" do
    let(:user) { nil }

    it "cannot read any resource" do
      expect(ability.can?(:read, Category.new)).to be false
      expect(ability.can?(:read, Payment.new)).to be false
    end
  end

  context "when a regular user" do
    let(:user)       { create(:user) }
    let(:own_cat)    { create(:category, user: user) }
    let(:other_user) { create(:user) }
    let(:other_cat)  { create(:category, user: other_user) }

    it "can manage own categories" do
      expect(ability.can?(:manage, own_cat)).to be true
    end

    it "cannot manage another user's categories" do
      expect(ability.can?(:manage, other_cat)).to be false
    end

    it "can manage own payments" do
      payment = create(:payment, user: user, category: own_cat)
      expect(ability.can?(:manage, payment)).to be true
    end

    it "cannot manage another user's payments" do
      payment = create(:payment, user: other_user, category: other_cat)
      expect(ability.can?(:manage, payment)).to be false
    end

    it "can manage own budgets" do
      budget = create(:budget, user: user, category: own_cat)
      expect(ability.can?(:manage, budget)).to be true
    end

    it "can manage own debts" do
      debt = create(:debt, user: user)
      expect(ability.can?(:manage, debt)).to be true
    end

    it "can manage own financial goals" do
      goal = create(:financial_goal, user: user)
      expect(ability.can?(:manage, goal)).to be true
    end

    it "can manage own investments" do
      investment = create(:investment, user: user)
      expect(ability.can?(:manage, investment)).to be true
    end

    it "can manage own recurring transactions" do
      rt = create(:recurring_transaction, user: user, category: own_cat)
      expect(ability.can?(:manage, rt)).to be true
    end

    it "cannot manage :all (admin privilege)" do
      expect(ability.can?(:manage, :all)).to be false
    end
  end

  context "when an admin user" do
    let(:user) { create(:user, :admin) }

    it "can manage :all" do
      expect(ability.can?(:manage, :all)).to be true
    end

    it "can manage another user's category" do
      other_cat = create(:category, user: create(:user))
      expect(ability.can?(:manage, other_cat)).to be true
    end
  end
end

