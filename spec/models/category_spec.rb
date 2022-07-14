require 'rails_helper'

RSpec.describe Category, type: :model do
  before(:each) do
    @user = User.create(name: 'John Doe', email: 'test@emal.com', password: 'password')
    @category = Category.create(name: 'Test Category', icon: 'user.png', user_id: @user.id)
  end

  describe 'Category validations' do
    it 'should be valid' do
      expect(@category).to be_valid
    end

    it 'should not be valid without a name' do
      @category.name = nil
      expect(@category).to_not be_valid
    end

    it 'should not be valid without an icon' do
      @category.icon = nil
      expect(@category).to_not be_valid
    end
  end
end
