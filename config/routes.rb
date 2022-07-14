Rails.application.routes.draw do
  devise_for :users

  devise_scope :user do
    get '/users/sign_out' => 'devise/sessions#destroy'
  end
  
  root to: "pages#index"
  resources :users, only: %i[index]
  resources :categories, only: %i[index new create show update destroy] do
    resources :payments, only: %i[index new create show update destroy]
  end
end