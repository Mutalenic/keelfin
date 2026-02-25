require 'rails_helper'

RSpec.describe 'users/index', type: :feature do
  before(:each) do
    @user = User.create(name: 'John Doe', email: 'gutasd@kio.com', password: 'password')
    login_as(@user, scope: :user)
    visit root_path
  end

  describe 'User index page' do
    it 'should show the dashboard' do
      expect(page).to have_content('Your Financial Dashboard')
      expect(page).to have_content("This Month's Spending")
    end
  end
end
