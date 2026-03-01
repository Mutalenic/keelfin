require 'rails_helper'

RSpec.describe User, type: :model do
  before do
    @user = described_class.create(name: 'John Doe', email: 'naysh@jhd.com', password: 'password')
  end

  describe 'User validations' do
    it 'is valid' do
      expect(@user).to be_valid
    end

    it 'is not valid without a name' do
      @user.name = nil
      expect(@user).not_to be_valid
    end

    it 'is not valid without an email' do
      @user.email = nil
      expect(@user).not_to be_valid
    end

    it 'is invalid if name is too long' do
      @user.name = 'a' * 51
      expect(@user).not_to be_valid
    end
  end
end
