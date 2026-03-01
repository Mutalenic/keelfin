require 'rails_helper'

RSpec.describe Payment, type: :model do
  before do
    @user = User.create(name: 'John Doe', email: 'example@gmail.com', password: 'password')
    @category = Category.create(name: 'Test Category', icon: 'user.png', user_id: @user.id)
    @payment = described_class.create(name: 'Test Payment', amount: 100, user_id: @user.id, category_id: @category.id)
  end

  describe 'Payment validations' do
    it 'is valid' do
      expect(@payment).to be_valid
    end

    it 'is not valid without a name' do
      @payment.name = nil
      expect(@payment).not_to be_valid
    end

    it 'is not valid without an amount' do
      @payment.amount = nil
      expect(@payment).not_to be_valid
    end

    it 'is invalid if name is too long' do
      @payment.name = 'a' * 51
      expect(@payment).not_to be_valid
    end
  end
end
