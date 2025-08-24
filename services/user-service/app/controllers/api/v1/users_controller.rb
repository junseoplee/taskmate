class Api::V1::UsersController < ApplicationController
  before_action :authenticate_user!, except: [ :show ]
  before_action :find_user, only: [ :show ]

  # GET /api/v1/users/profile
  def profile
    render json: {
      status: "success",
      user: {
        id: current_user.id,
        email: current_user.email,
        name: current_user.name,
        created_at: current_user.created_at,
        updated_at: current_user.updated_at
      }
    }
  end

  # PUT /api/v1/users/profile
  def update_profile
    user_params = params.require(:user).permit(:name, :current_password, :password, :password_confirmation)

    # 현재 비밀번호 확인 (비밀번호 변경 시)
    if user_params[:password].present?
      unless current_user.authenticate(user_params[:current_password])
        return render json: {
          status: "error",
          error: "authentication_failed",
          message: "Current password is incorrect"
        }, status: :unauthorized
      end
    end

    if current_user.update(user_params.except(:current_password))
      render json: {
        status: "success",
        user: {
          id: current_user.id,
          email: current_user.email,
          name: current_user.name,
          updated_at: current_user.updated_at
        },
        message: "Profile updated successfully"
      }
    else
      render json: {
        status: "error",
        error: "validation_failed",
        message: "Profile update failed",
        details: current_user.errors
      }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/users/:id (내부 API)
  def show
    if @user
      render json: {
        status: "success",
        user: {
          id: @user.id,
          email: @user.email,
          name: @user.name,
          created_at: @user.created_at
        }
      }
    else
      render json: {
        status: "error",
        error: "user_not_found",
        message: "User not found"
      }, status: :not_found
    end
  end

  private

  def find_user
    @user = User.find_by(id: params[:id])
  end

  def authenticate_user!
    token = request.headers["Authorization"]&.gsub("Bearer ", "")

    if token.blank?
      return render json: {
        status: "error",
        error: "authentication_required",
        message: "Authentication token required"
      }, status: :unauthorized
    end

    session = Session.find_by(token: token)

    if session.nil? || !session.valid_session?
      return render json: {
        status: "error",
        error: "invalid_token",
        message: "Invalid or expired session token"
      }, status: :unauthorized
    end

    @current_user = session.user
    session.touch # 세션 갱신
  end

  def current_user
    @current_user
  end
end
