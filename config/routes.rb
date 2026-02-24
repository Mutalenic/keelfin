Rails.application.routes.draw do
  devise_for :users

  devise_scope :user do
    get '/users/sign_out' => 'devise/sessions#destroy'
  end
  
  root to: "dashboard#index"
  
  get 'dashboard', to: 'dashboard#index'
  
  resources :users, only: %i[index]
  resources :debts
  resources :budgets
  
  resources :categories, only: %i[index new create show update destroy] do
    resources :payments, only: %i[index new create show update destroy]
  end
end