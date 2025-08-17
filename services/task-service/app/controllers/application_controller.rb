class ApplicationController < ActionController::API
  include ActionController::Cookies
  
  # User Service 인증 검증
  before_action :authenticate_user!
  
  protected
  
  def authenticate_user!
    # Check both cookie and Authorization header for microservices compatibility
    token = cookies[:session_token]
    
    # If no cookie, check Authorization header
    if token.blank?
      auth_header = request.headers['Authorization']
      if auth_header&.start_with?('Bearer ')
        token = auth_header.split(' ').last
      end
    end
    
    unless token
      render json: { 
        success: false, 
        error: "Authentication required" 
      }, status: :unauthorized
      return
    end
    
    # User Service에서 세션 검증 (AuthService 사용)
    auth_result = AuthService.new.verify_session(token)
    
    if auth_result[:success]
      @current_user_id = auth_result[:user]['id']
      @current_user = auth_result[:user]
    else
      error_message = auth_result[:error]
      status_code = case error_message
                   when /unavailable/
                     :service_unavailable
                   else
                     :unauthorized
                   end
                   
      render json: { 
        success: false, 
        error: error_message
      }, status: status_code
    end
  end
  
  def current_user
    @current_user
  end
end