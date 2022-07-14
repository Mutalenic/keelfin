require 'rails_helper'

RSpec.describe 'payment/index', type: :feature do
  before(:each) do
    @user = User.create(name: 'John Doe', email: 'jgokp@tmail.com', password: 'password')
    @category = Category.create(name: 'Test Category', icon: 'user.png', user_id: @user.id)
    @payment = Payment.create(name: 'Test Payment', amount: 100, user_id: @user.id, category_id: @category.id)
    visit new_user_session_path
    fill_in 'Email', with: 'jgokp@tmail.com'
    fill_in 'Password', with: 'password'
    click_button 'Log in'
    visit(new_category_payment_path(@category))
  end



  context 'Test item page' do
    it 'I can access this page if user is connected' do
      expect(page).to have_content 'transactions'
      expect(page).to have_content 'Add A New Payment'
    end

      scenario 'confirm that form has a submit button' do
    expect(page).to have_css('input[type=submit]')
  end

  scenario 'confirm that the form has a name field' do
    expect(page).to have_css('input[name=name]')
  end

  scenario 'confirm that the form has an amount field' do
    expect(page).to have_css('input[name=amount]')
  end
end
end
