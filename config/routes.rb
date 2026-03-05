Rails.application.routes.draw do
  resource :subscription, only: [:show, :new, :create, :update] do
    collection do
      get :plans
      post :upgrade
    end
    member do
      post :cancel
    end
  end
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    passwords: 'users/passwords',
    confirmations: 'users/confirmations'
  }

  devise_scope :user do
    delete '/users/sign_out' => 'users/sessions#destroy'
  end

  # Onboarding
  get 'onboarding', to: 'onboarding#show'
  post 'onboarding', to: 'onboarding#update'
  get 'onboarding/complete', to: 'onboarding#complete', as: :onboarding_complete
  
  root to: "dashboard#index"
  
  get 'dashboard', to: 'dashboard#index'
  get 'coming_soon', to: 'coming_soon#index'

  resources :debts
  resources :budgets
  
  resources :financial_goals do
    member do
      patch :update_progress
    end
  end
  
  resources :recurring_transactions do
    member do
      patch :toggle_active
    end
    collection do
      post :process_due
    end
  end
  
  resources :investments do
    member do
      patch :update_value
    end
    resources :investment_transactions
  end
  
  resources :categories, only: %i[index new create show edit update destroy] do
    resources :payments, only: %i[index new create show update destroy]
    collection do
      post :add_preset
    end
  end

  # Admin CMS
  namespace :admin do
    root to: 'dashboard#index'
    resources :users, only: [:index, :show, :edit, :update] do
      member do
        patch :toggle_admin
        patch :impersonate
      end
    end
    resources :subscriptions, only: [:index, :show, :edit, :update]
    resources :category_presets
    resources :economic_indicators
    resources :bnnb_datas, path: 'bnnb-data'
  end
end