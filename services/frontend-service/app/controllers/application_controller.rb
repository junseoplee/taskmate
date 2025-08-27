class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  helper_method :current_user

  protected

  def current_user
    return @current_user if defined?(@current_user)

    # Try to get token from Authorization header first (API requests)
    @session_token = extract_token_from_header

    # Fallback to Rails session (browser requests)
    @session_token ||= session[:session_token]

    Rails.logger.info "Current session token: #{@session_token ? @session_token[0..8] + '...' : 'blank'}"

    return nil unless @session_token

    Rails.logger.info "Verifying session token: #{@session_token[0..8]}..."
    @current_user ||= verify_session_token(@session_token)
  end

  # Helper method to get current session token
  def current_session_token
    @session_token
  end

  def authenticate_user!
    unless current_user
      # If Bearer token was attempted but failed, always return JSON response
      if request.headers["Authorization"]&.start_with?("Bearer ")
        render json: { success: false, error: "Authentication required" }, status: :unauthorized
        return
      end

      # For browser requests without Bearer tokens, use appropriate response format
      respond_to do |format|
        format.html { redirect_to auth_login_path }
        format.json { render json: { success: false, error: "Authentication required" }, status: :unauthorized }
      end
    end
  end

  def login_user(session_token)
    session[:session_token] = session_token
    @current_user = nil  # Reset memoized user
  end

  def logout_user
    session[:session_token] = nil
    @current_user = nil
  end

  private

  def extract_token_from_header
    authorization_header = request.headers["Authorization"]
    return nil unless authorization_header

    # Extract Bearer token from "Bearer <token>" format
    token = authorization_header.split(" ").last
    return token if authorization_header.start_with?("Bearer ")

    nil
  end

  def verify_session_token(token)
    user_client = UserServiceClient.new
    response = user_client.verify_session(token)

    Rails.logger.info "Session verification for token #{token[0..8]}... - Response: #{response.inspect}"

    if response.is_a?(Hash) && response["success"]
      Rails.logger.info "Session verified successfully for user: #{response['user']}"
      response["user"]
    elsif response.respond_to?(:success?) && response.success?
      user_data = response.parsed_response
      if user_data && user_data["success"]
        Rails.logger.info "Session verified successfully (HTTParty): #{user_data['user']}"
        user_data["user"]
      else
        Rails.logger.error "Session verification failed: #{user_data}"
        session[:session_token] = nil
        nil
      end
    else
      Rails.logger.error "Session verification failed: #{response}"
      session[:session_token] = nil
      nil
    end
  rescue => e
    Rails.logger.error "Session verification failed with exception: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    session[:session_token] = nil
    nil
  end
end
