require 'rails_helper'

RSpec.describe 'category/index', type: :feature do
  before do
    @user = User.create(name: 'John Doe', email: 'johntest@test.com', password: 'password')
    @category = Category.create(name: 'Test Category', icon: 'user.png', user_id: @user.id)
    @payment = Payment.create(name: 'Test Payment', amount: 100, user_id: @user.id, category_id: @category.id)

    visit new_user_session_path
    fill_in 'Email', with: 'johntest@test.com'
    fill_in 'Password', with: 'password'
    click_button 'Log in'
  end

  it 'shows the category name' do
    visit categories_path
    expect(page).to have_content('Test Category')
  end

  it 'shows the category total amount' do
    visit categories_path
    expect(page).to have_content(100.00)
  end

  it 'I can access this page if user is connected' do
    visit categories_path
    expect(page).to have_content('Test Category')
    expect(page).to have_content(@category.name)
  end

  it 'I can access this page if user is not connected' do
    visit new_category_path
    expect(page).not_to have_content('Test Category')
    expect(page).to have_css('form')
    expect(page).to have_css('input[type=submit]')
  end
end
