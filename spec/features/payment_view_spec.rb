require 'rails_helper'

RSpec.describe 'payment/index', type: :feature do
  let(:user) { User.create(name: 'John Doe', email: 'jgokp@tmail.com', password: 'password') }
  let(:category) { Category.create(name: 'Test Category', icon: 'user.png', user_id: user.id) }
  let(:payment) { Payment.create(name: 'Test Payment', amount: 100, user_id: user.id, category_id: category.id) }

  before do
    payment # ensure payment (and user + category) exist before visiting
    visit new_user_session_path
    fill_in 'Email', with: 'jgokp@tmail.com'
    fill_in 'Password', with: 'password'
    click_button 'Log in'
    visit(new_category_payment_path(category))
  end

  context 'Test item page' do
    it 'I can access this page if user is connected' do
      expect(page).to have_content 'transactions'
      expect(page).to have_content 'Add New Payment'
    end

    scenario 'confirm that form has a submit button' do
      expect(page).to have_css('input[type=submit]')
    end

    scenario 'confirm that the form has a name field' do
      expect(page).to have_css('input[name="payment[name]"]')
    end

    scenario 'confirm that the form has an amount field' do
      expect(page).to have_css('input[name="payment[amount]"]')
    end
  end
end
