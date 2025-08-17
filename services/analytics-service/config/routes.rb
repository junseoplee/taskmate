Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Analytics API routes
  resources :analytics_events, only: [ :index, :show, :create ] do
    collection do
      get :metrics
    end
  end

  resources :analytics_summaries, only: [ :index, :show, :create ] do
    collection do
      get :dashboard
      get :chart_data
    end
  end

  # Root route for API info
  root to: proc { [ 200, {}, [ '{"service":"Analytics Service","version":"1.0.0","status":"running"}' ] ] }
end
