require 'rails_helper'

RSpec.describe 'users/index', type: :feature do
  before(:each) do
    @user = User.create(name: 'John Doe', email: 'gutasd@kio.com', password: 'password')
    visit root_path
  end

  describe 'User index page' do
    it 'should show the user name' do
      expect(page).to have_content('DigiBudget')
    end
  end
end
