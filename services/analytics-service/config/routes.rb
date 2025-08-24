Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Analytics dashboard and main stats
      get "analytics/dashboard", to: "analytics#dashboard"

      # Task-specific analytics
      get "analytics/tasks/completion-rate", to: "analytics#completion_rate"
      get "analytics/completion-trend", to: "analytics#completion_trend"
      get "analytics/priority-distribution", to: "analytics#priority_distribution"

      # Event collection endpoint (internal API)
      post "analytics/events", to: "analytics#create_event"

      # Health check
      get "health", to: "health#show"
    end
  end

  # Root route for API info
  root to: proc { [ 200, {}, [ '{"service":"Analytics Service","version":"1.0.0","status":"running"}' ] ] }
end
