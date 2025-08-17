Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :file_categories do
        member do
          get :file_types
          post :validate_file
        end
      end

      resources :file_attachments do
        member do
          post :upload_complete
          post :upload_failed
        end
      end
    end
  end

  # Root route for API info
  root to: proc { [ 200, {}, [ 'File Service API v1.0' ] ] }
end
