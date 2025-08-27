# frozen_string_literal: true

class ApplicationController < ActionController::API
  # Basic API error handling
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  protected

  # Get current user from request headers
  def current_user
    return @current_user if defined?(@current_user)

    session_token = extract_session_token
    return nil unless session_token

    # Verify session with User Service
    auth_result = AuthService.new.verify_session(session_token)

    if auth_result[:success]
      @current_user = auth_result[:user]
    else
      Rails.logger.error "Session verification failed: #{auth_result[:error]}"
      nil
    end
  end

  # Verify user authentication
  def authenticate_user!
    unless current_user
      render json: {
        status: "error",
        message: "Authentication required"
      }, status: :unauthorized
    end
  end

  private

  def render_not_found
    render json: { error: "Record not found" }, status: :not_found
  end

  def extract_session_token
    # Try Authorization header first (Bearer token)
    auth_header = request.headers["Authorization"]
    return auth_header.split(" ").last if auth_header&.start_with?("Bearer ")

    # Try X-Session-Token header
    request.headers["X-Session-Token"]
  end
end
