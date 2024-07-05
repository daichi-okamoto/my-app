Rails.application.routes.draw do
  get 'dashboard/index'
  post 'shifts/create_schedule', to: 'shifts#create_schedule', as: 'create_schedule'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  root "tops#index"
  resources :users, only: %i[new create] 
  resources :employees
  resources :shifts, only: %i[index new create]
  get 'login', to: 'user_sessions#new'
  post 'login', to: 'user_sessions#create'
  delete 'logout', to: 'user_sessions#destroy'
end
