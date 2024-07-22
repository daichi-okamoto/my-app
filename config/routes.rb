Rails.application.routes.draw do
  get 'contacts/new'
  get 'contacts/create'
  get 'dashboard/index'
  get 'shifts/edit_schedule', to: 'shifts#edit_schedule', as: 'edit_schedule'
  get 'shifts/export_excel', to: 'shifts#export_excel', defaults: { format: :xlsx }, as: 'export_excel'
  get 'privacy_policy', to: 'static_pages#privacy_policy'
  get 'inquiry', to: 'static_pages#inquiry'
  post 'shifts/create_schedule', to: 'shifts#create_schedule', as: 'create_schedule'
  patch 'shifts/update_schedule', to: 'shifts#update_schedule', as: 'update_schedule'
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
  resources :contacts, only: [:new, :create]
  get 'login', to: 'user_sessions#new'
  post 'login', to: 'user_sessions#create'
  delete 'logout', to: 'user_sessions#destroy'
end
