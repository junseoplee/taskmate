class AuthService
  include HTTParty
  
  base_uri ENV.fetch('USER_SERVICE_URL', 'http://localhost:3000')
  default_timeout 5

  def initialize
    # Circuit breaker pattern would require the circuit_breaker gem
    # For now, implementing basic retry logic
    @max_retries = 3
    @retry_delay = 1 # seconds
  end

  def verify_session(token)
    with_retry do
      response = self.class.get(
        '/api/v1/auth/verify',
        headers: { 'Authorization' => "Bearer #{token}" },
        timeout: 5
      )

      Rails.logger.info "AuthService response status: #{response.code}"
      Rails.logger.info "AuthService response body: #{response.body}"
      
      if response.success?
        parsed = response.parsed_response
        if parsed['success']
          { success: true, user: parsed['user'] }
        else
          { success: false, error: parsed['error'] || 'Invalid session' }
        end
      else
        error_message = response.parsed_response.is_a?(Hash) ? 
                       (response.parsed_response['error'] || 'Invalid session') : 
                       'Invalid session'
        { success: false, error: error_message }
      end
    end
  rescue Net::TimeoutError, Errno::ECONNREFUSED => e
    Rails.logger.error "AuthService timeout/connection error: #{e.message}"
    { success: false, error: 'User service unavailable' }
  rescue StandardError => e
    Rails.logger.error "AuthService error: #{e.message}"
    { success: false, error: 'Authentication service error' }
  end

  def get_user(user_id)
    with_retry do
      response = self.class.get(
        "/api/v1/users/#{user_id}",
        timeout: 5
      )

      if response.success?
        { success: true, user: response.parsed_response['user'] }
      else
        { success: false, error: response.parsed_response['error'] || 'User not found' }
      end
    end
  rescue Net::TimeoutError, Errno::ECONNREFUSED => e
    Rails.logger.error "AuthService timeout/connection error: #{e.message}"
    { success: false, error: 'User service unavailable' }
  rescue StandardError => e
    Rails.logger.error "AuthService error: #{e.message}"
    { success: false, error: 'User service error' }
  end

  private

  def with_retry
    attempts = 0
    begin
      attempts += 1
      yield
    rescue Net::TimeoutError, Errno::ECONNREFUSED => e
      if attempts <= @max_retries
        Rails.logger.warn "AuthService retry attempt #{attempts}/#{@max_retries}: #{e.message}"
        sleep(@retry_delay * attempts) # Exponential backoff
        retry
      else
        raise e
      end
    end
  end
end