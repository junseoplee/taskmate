class AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:login, :create, :register, :register_create]
  
  def login
    redirect_to dashboard_path if current_user
  end
  
  def create
    user_client = UserServiceClient.new
    response = user_client.login(params[:email], params[:password])
    
    Rails.logger.info "Login response: #{response.inspect}"
    Rails.logger.info "Response code: #{response.code}"
    Rails.logger.info "Response body: #{response.body}"
    
    if response.success?
      data = response.parsed_response
      login_user(data['session_token'])
      redirect_to dashboard_path, notice: 'Login successful.'
    else
      error_msg = response.parsed_response['error'] rescue response.body
      Rails.logger.error "Login failed: #{error_msg}"
      flash.now[:alert] = error_msg || 'Login failed.'
      render :login, status: :unprocessable_content
    end
  rescue => e
    Rails.logger.error "Login exception: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    flash.now[:alert] = "Service connection error: #{e.message}"
    render :login, status: :service_unavailable
  end
  
  def register
    redirect_to dashboard_path if current_user
  end
  
  def register_create
    user_client = UserServiceClient.new
    response = user_client.register(
      params[:name], 
      params[:email], 
      params[:password], 
      params[:password_confirmation]
    )
    
    if response.success?
      data = response.parsed_response
      login_user(data['session_token'])
      redirect_to dashboard_path, notice: 'Registration completed successfully.'
    else
      flash.now[:alert] = response.parsed_response['error'] || 'Registration failed.'
      render :register, status: :unprocessable_entity
    end
  rescue => e
    flash.now[:alert] = 'Service connection error occurred.'
    render :register, status: :service_unavailable
  end
  
  def logout
    if current_user && session[:session_token]
      # Call User Service logout API
      begin
        user_client = UserServiceClient.new
        user_client.logout(session[:session_token])
      rescue => e
        Rails.logger.error "Logout API call failed: #{e.message}"
      end
    end
    
    # Clear local session
    logout_user
    redirect_to auth_login_path, notice: 'Logged out successfully.'
  end
end