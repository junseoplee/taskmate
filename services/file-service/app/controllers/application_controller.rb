class ApplicationController < ActionController::API
  before_action :set_default_response_format

  private

  def set_default_response_format
    request.format = :json
  end

  def render_success(data, status: :ok, message: nil)
    response = { data: data }
    response[:message] = message if message.present?
    render json: response, status: status
  end

  def render_error(errors, status: :unprocessable_entity, message: nil)
    response = { errors: errors }
    response[:message] = message if message.present?
    render json: response, status: status
  end

  def render_not_found(message = "Resource not found")
    render json: { message: message }, status: :not_found
  end
end
