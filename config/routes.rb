require 'sidekiq/web'

Rails.application.routes.draw do
  resource :subscription, only: [:show, :new, :create, :update] do
    collection do
      get :plans
      post :upgrade
      post :checkout
      get :dpo_callback
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
  get 'terms',   to: 'public_pages#terms',   as: :terms
  get 'privacy', to: 'public_pages#privacy', as: :privacy
  get 'coming_soon', to: 'coming_soon#index'
  get 'annual_overview', to: 'annual_overview#index', as: :annual_overview
  get 'financial_analysis', to: 'financial_analysis#index', as: :financial_analysis

  resources :income_sources
  
  post 'payments', to: 'payments#create_global', as: :global_payments

  resources :debts do
    resources :debt_payments, only: %i[create destroy]
  end
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
  
  get 'payments/export', to: 'payments#export_all', as: :export_all_payments

  resources :categories, only: %i[index new create show edit update destroy] do
    resources :payments, only: %i[index new create show update destroy] do
      collection do
        get :export
      end
    end
    collection do
      post :add_preset
    end
  end

  # Sidekiq Web UI — admin-only, session-authenticated (not JWT)
  authenticate :user, ->(u) { u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  # -----------------------------------------------------------------------
  # REST API — JWT authenticated, versioned, CORS-enabled
  # We use `devise_scope :user` (not a second `devise_for`) to avoid duplicate
  # Devise mappings and keep the API session routes on the `:user` scope.
  # -----------------------------------------------------------------------
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      devise_scope :user do
        post   'auth/sign_in',  to: 'sessions#create'
        delete 'auth/sign_out', to: 'sessions#destroy'
      end

      resources :accounts, only: %i[index show create] do
        member { get :balance }
      end

      resources :ledger_transactions, only: %i[index show create]
      resources :audit_logs,          only: %i[index]
      resources :webhook_endpoints,   only: %i[index create destroy]
      resources :webhook_deliveries,  only: %i[index]
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
      collection do
        delete :stop_impersonating
      end
    end
    resources :subscriptions, only: [:index, :show, :edit, :update]
    resources :category_presets
    resources :economic_indicators
    resources :bnnb_datas, path: 'bnnb-data'
  end
end