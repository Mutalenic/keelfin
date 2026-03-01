require 'rails_helper'

RSpec.feature 'login page', type: :feature do
  before do
    @user = User.create(name: 'John Doe', email: 'jognd@ymail.com', password: 'password')
  end

  background { visit new_user_session_path }
  scenario 'displays form fields' do
    expect(page).to have_field('user[email]')
    expect(page).to have_field('user[password]')
    expect(page).to have_button('Log in')
  end

  describe 'Login information' do
    it 'does not login with invalid information' do
      click_button 'Log in'
      expect(page).to have_content('Invalid Email or password.')
    end

    it 'logins with valid information' do
      visit new_user_session_path
      fill_in 'Email', with: 'jognd@ymail.com'
      fill_in 'Password', with: 'password'
      click_button 'Log in'
    end
  end
end
