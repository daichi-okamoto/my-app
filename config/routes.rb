Rails.application.routes.draw do
  get 'dashboard/index'
  post 'shifts/create_schedule', to: 'shifts#create_schedule', as: 'create_schedule'
  delete 'shifts/destroy_all', to: 'shifts#destroy_all', as: 'destroy_all_shifts'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  root "tops#index"
  resources :users, only: %i[new create] 
  resources :employees
  resources :shifts, only: %i[index new create edit update]
  resources :shift_requests, only: %i[new create destroy]
  resources :memos, only: [:create]
  get 'login', to: 'user_sessions#new'
  post 'login', to: 'user_sessions#create'
  delete 'logout', to: 'user_sessions#destroy'
end
