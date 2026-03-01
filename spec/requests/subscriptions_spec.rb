require 'rails_helper'

RSpec.describe 'Subscriptions', type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  # ensure_user_subscription before_action creates a free subscription for any
  # user who doesn't have one, so GET /subscription always has a subscription
  # by the time set_subscription fires.
  describe 'GET /subscription' do
    it 'returns http success (ensure_subscription creates one if absent)' do
      get subscription_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /subscription/new' do
    context 'when user has no subscription' do
      it 'redirects to plans (ensure_subscription creates one, new redirects)' do
        get new_subscription_path
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when user already has a subscription' do
      before { create(:subscription, user: user) }

      it 'redirects to plans' do
        get new_subscription_path
        expect(response).to redirect_to(plans_subscription_path)
      end
    end
  end

  describe 'POST /subscription' do
    it 'creates a free subscription and redirects' do
      expect do
        post subscription_path
      end.to change(Subscription, :count).by(1)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'GET /subscription/plans' do
    it 'returns http success' do
      get plans_subscription_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /subscription' do
    before { create(:subscription, user: user) }

    it 'redirects after update' do
      patch subscription_path, params: { subscription: { plan_name: 'free' } }
      expect(response).to have_http_status(:redirect)
    end
  end
end
