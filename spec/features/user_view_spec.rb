require 'rails_helper'

RSpec.describe 'users/index', type: :feature do
  before do
    @user = User.create(name: 'John Doe', email: 'gutasd@kio.com', password: 'password', confirmed_at: Time.current)
    login_as(@user, scope: :user)
    visit root_path
  end

  describe 'User index page' do
    it 'shows the dashboard' do
      expect(page).to have_content('Dashboard')
      expect(page).to have_content('Monthly Income')
    end
  end
end
