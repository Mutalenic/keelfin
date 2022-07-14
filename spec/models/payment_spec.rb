require 'rails_helper'

RSpec.describe Payment, type: :model do
  before(:each) do
    @user = User.create(name: 'John Doe', email: 'example@gmail.com', password: 'password')
    @category = Category.create(name: 'Test Category', icon: 'user.png', user_id: @user.id)
    @payment = Payment.create(name: 'Test Payment', amount: 100, user_id: @user.id, category_id: @category.id)
  end

  describe 'Payment validations' do
    it 'should be valid' do
      expect(@payment).to be_valid
    end

    it 'should not be valid without a name' do
      @payment.name = nil
      expect(@payment).to_not be_valid
    end

    it 'should not be valid without an amount' do
      @payment.amount = nil
      expect(@payment).to_not be_valid
    end

    it 'is invalid if name is too long' do
      @payment.name = 'a' * 51
      expect(@payment).to_not be_valid
    end
  end
end
