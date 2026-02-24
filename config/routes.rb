Rails.application.routes.draw do
  devise_for :users

  devise_scope :user do
    delete '/users/sign_out' => 'devise/sessions#destroy'
  end
  
  root to: "dashboard#index"
  
  get 'dashboard', to: 'dashboard#index'
  
  resources :users, only: %i[index]
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
  end
end