class DebugController < ApplicationController
  skip_before_action :authenticate_user!, only: [:auth]
  
  def auth
    current_user_data = current_user
    session_token = session[:session_token]
    
    render json: {
      has_current_user: !current_user_data.nil?,
      current_user: current_user_data,
      session_token: session_token,
      rails_env: Rails.env,
      timestamp: Time.current
    }
  end
end