class Api::V1::AuthController < ApplicationController
  before_action :require_session, only: [ :logout, :verify ]

  def register
    user = User.new(user_params)

    if user.save
      session = user.sessions.create!
      set_session_cookie(session.token)

      render json: {
        success: true,
        user: user_response(user)
      }, status: :created
    else
      render json: {
        success: false,
        errors: user.errors.full_messages
      }, status: :unprocessable_content
    end
  end

  def login
    user = User.find_by(email: login_params[:email])

    if user&.authenticate(login_params[:password])
      # Destroy existing sessions for the user
      user.sessions.destroy_all

      # Create new session
      session = user.sessions.create!
      set_session_cookie(session.token)

      render json: {
        success: true,
        user: user_response(user)
      }, status: :ok
    else
      render json: {
        success: false,
        error: "Invalid email or password"
      }, status: :unauthorized
    end
  end

  def logout
    if @current_session
      @current_session.destroy
      clear_session_cookie

      render json: {
        success: true,
        message: "Logged out successfully"
      }, status: :ok
    else
      render json: {
        success: false,
        error: "No active session found"
      }, status: :unauthorized
    end
  end

  def verify
    if @current_session
      # Extend session expiry
      @current_session.extend_expiry!

      render json: {
        success: true,
        user: user_response(@current_user)
      }, status: :ok
    else
      render json: {
        success: false,
        error: "Session expired"
      }, status: :unauthorized
    end
  end

  private

  def user_params
    params.permit(:name, :email, :password, :password_confirmation)
  end

  def login_params
    params.permit(:email, :password)
  end

  def user_response(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      created_at: user.created_at
    }
  end

  def set_session_cookie(token)
    cookies[:session_token] = {
      value: token,
      httponly: true,
      secure: Rails.env.production?,
      same_site: :lax
    }
  end

  def clear_session_cookie
    cookies.delete(:session_token)
  end

  def require_session
    token = cookies[:session_token]

    unless token
      render json: {
        success: false,
        error: "No session token provided"
      }, status: :unauthorized
      return
    end

    @current_session = Session.joins(:user).find_by(token: token)

    unless @current_session
      render json: {
        success: false,
        error: "Invalid session token"
      }, status: :unauthorized
      return
    end

    unless @current_session.valid_session?
      @current_session.destroy
      render json: {
        success: false,
        error: "Session expired"
      }, status: :unauthorized
      return
    end

    @current_user = @current_session.user
  end
end
