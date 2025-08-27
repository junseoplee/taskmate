require "httparty"

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
          "success" => false,
          "message" => "Service connection failed. Please try again later.",
          "error" => e.message
        }
      end
    rescue => e
      Rails.logger.error "Unexpected error in service request: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      {
        "success" => false,
        "message" => "An error occurred while processing the service request.",
        "error" => e.message
      }
    end
  end

  private

  def prepare_options(options)
    # Start with default headers
    headers = {
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }

    # Merge any provided headers
    if options[:headers]
      headers.merge!(options[:headers])
    end

    # Prepare final options
    merged_options = {
      timeout: @timeout,
      headers: headers
    }

    # Add other options except headers
    options.each do |key, value|
      next if key == :headers
      merged_options[key] = value
    end

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
      response.parsed_response || { "success" => true }
    when 400
      {
        "success" => false,
        "message" => response.parsed_response&.dig("message") || "Invalid request."
      }
    when 401
      {
        "success" => false,
        "message" => "Authentication required."
      }
    when 403
      {
        "success" => false,
        "message" => "Access denied."
      }
    when 404
      {
        "success" => false,
        "message" => "Requested resource not found."
      }
    when 422
      {
        "success" => false,
        "message" => response.parsed_response&.dig("message") || "Input data is invalid."
      }
    when 500..599
      {
        "success" => false,
        "message" => "Server error occurred. Please contact the administrator."
      }
    else
      {
        "success" => false,
        "message" => "Unknown error occurred."
      }
    end
  end

  def build_query_params(params)
    params.compact.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join("&")
  end

  # HTTP method helpers for service clients
  def get(path, options = {})
    url = build_url(path, options[:query])
    make_request(:get, url, options.except(:query))
  end

  def post(path, options = {})
    url = build_url(path)
    make_request(:post, url, options)
  end

  def put(path, options = {})
    url = build_url(path)
    make_request(:put, url, options)
  end

  def delete(path, options = {})
    url = build_url(path)
    make_request(:delete, url, options)
  end

  # Error handling for service clients
  def handle_error(error, context_message)
    Rails.logger.error "#{context_message}: #{error.message}"
    Rails.logger.error error.backtrace.join("\n") if error.respond_to?(:backtrace)
    {
      "success" => false,
      "message" => context_message,
      "error" => error.message
    }
  end

  # Authentication headers helper
  def auth_headers(session_token: nil)
    headers = {
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }
    headers["Authorization"] = "Bearer #{session_token}" if session_token
    headers
  end

  private

  def build_url(path, query_params = nil)
    url = "#{base_url}#{path}"
    if query_params && !query_params.empty?
      query_string = build_query_params(query_params)
      url += "?#{query_string}" unless query_string.empty?
    end
    url
  end

  # Abstract method - must be implemented by subclasses
  def base_url
    raise NotImplementedError, "Subclasses must implement base_url method"
  end
end
