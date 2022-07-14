require 'rails_helper'

RSpec.describe User, type: :model do
  before(:each) do
    @user = User.create(name: 'John Doe', email: 'naysh@jhd.com', password: 'password')
  end

  describe 'User validations' do
    it 'should be valid' do
      expect(@user).to be_valid
    end

    it 'should not be valid without a name' do
      @user.name = nil
      expect(@user).to_not be_valid
    end

    it 'should not be valid without an email' do
      @user.email = nil
      expect(@user).to_not be_valid
    end

    it 'is invalid if name is too long' do
      @user.name = 'a' * 51
      expect(@user).to_not be_valid
    end
  end
end
