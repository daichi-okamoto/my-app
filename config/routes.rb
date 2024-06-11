Rails.application.routes.draw do
  get 'dashboard/index'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  root "tops#index"
  resources :users, only: %i[new create] 
  get 'login', to: 'user_sessions#new'
  post 'login', to: 'user_sessions#create'
end
