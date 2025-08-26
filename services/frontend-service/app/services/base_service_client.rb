require 'httparty'

class BaseServiceClient
  include HTTParty
  
  # Default timeout settings
  default_timeout 10
  
  def initialize
    @timeout = 10
    @retries = 3
    @retry_delay = 1
  end

  protected

  def make_request(method, url, options = {})
    options = prepare_options(options)
    
    attempt = 0
    begin
      attempt += 1
      response = self.class.send(method, url, options)
      handle_response(response)
    rescue Net::TimeoutError, HTTParty::TimeoutError, Errno::ECONNREFUSED => e
      if attempt <= @retries
        Rails.logger.warn "Request failed (attempt #{attempt}): #{e.message}. Retrying in #{@retry_delay}s..."
        sleep(@retry_delay)
        retry
      else
        Rails.logger.error "Request failed after #{@retries} attempts: #{e.message}"
        {
          'success' => false,
          'message' => 'Service connection failed. Please try again later.',
          'error' => e.message
        }
      end
    rescue => e
      Rails.logger.error "Unexpected error in service request: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      {
        'success' => false,
        'message' => 'An error occurred while processing the service request.',
        'error' => e.message
      }
    end
  end

  private

  def prepare_options(options)
    default_options = {
      timeout: @timeout,
      headers: {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
    }
    
    # Merge provided options
    merged_options = default_options.merge(options)
    
    # Convert body to JSON if it's a hash
    if merged_options[:body].is_a?(Hash)
      merged_options[:body] = merged_options[:body].to_json
    end
    
    merged_options
  end

  def handle_response(response)
    case response.code
    when 200..299
      # Success response
      response.parsed_response || { 'success' => true }
    when 400
      {
        'success' => false,
        'message' => response.parsed_response&.dig('message') || 'Invalid request.'
      }
    when 401
      {
        'success' => false,
        'message' => 'Authentication required.'
      }
    when 403
      {
        'success' => false,
        'message' => 'Access denied.'
      }
    when 404
      {
        'success' => false,
        'message' => 'Requested resource not found.'
      }
    when 422
      {
        'success' => false,
        'message' => response.parsed_response&.dig('message') || 'Input data is invalid.'
      }
    when 500..599
      {
        'success' => false,
        'message' => 'Server error occurred. Please contact the administrator.'
      }
    else
      {
        'success' => false,
        'message' => 'Unknown error occurred.'
      }
    end
  end

  def build_query_params(params)
    params.compact.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')
  end
end