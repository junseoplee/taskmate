Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      namespace :auth do
        post :register
        post :login
        post :logout
        get :verify
      end

      # Users management
      resources :users, only: [ :show ] do
        collection do
          get :profile
          put :profile, action: :update_profile
        end
      end

      # Health check
      get :health, to: "health#show"
    end
  end
end
