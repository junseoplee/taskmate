Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balances and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Frontend Routes
  root "dashboard#index"

  # Authentication routes
  get "auth/login", to: "auth#login"
  post "auth/login", to: "auth#create"
  get "auth/register", to: "auth#register"
  post "auth/register", to: "auth#register_create"
  delete "auth/logout", to: "auth#logout"
  get "auth/logout", to: "auth#logout"

  # Dashboard
  get "dashboard", to: "dashboard#index"

  # Tasks
  resources :tasks do
    collection do
      get :search
      get :statistics
      get :overdue
      get :upcoming
      patch :bulk_update
    end
    member do
      patch :complete
    end
  end

  # Analytics
  get "analytics", to: "analytics#index"

  # Files
  get "files", to: "files#index"
  post "files/upload", to: "files#upload"
  post "files/add_url", to: "files#add_url"
  get "files/categories", to: "files#categories"
  post "files/categories", to: "files#create_category"
  get "files/:id/download", to: "files#download", as: :download_file
  delete "files/:id", to: "files#destroy"

  # Debug endpoint
  get "debug/auth", to: "debug#auth"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
