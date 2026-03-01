require 'rails_helper'

RSpec.describe Category, type: :model do
  before do
    @user = User.create(name: 'John Doe', email: 'test@emal.com', password: 'password')
    @category = described_class.create(name: 'Test Category', icon: 'user.png', user_id: @user.id)
  end

  describe 'Category validations' do
    it 'is valid' do
      expect(@category).to be_valid
    end

    it 'is not valid without a name' do
      @category.name = nil
      expect(@category).not_to be_valid
    end

    it 'is not valid without an icon' do
      @category.icon = nil
      expect(@category).not_to be_valid
    end
  end
end
