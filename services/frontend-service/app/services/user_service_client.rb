class UserServiceClient
  include HTTParty
  
  base_uri ENV.fetch('USER_SERVICE_URL', 'http://localhost:3000')
  
  def initialize
    @options = {
      headers: { 'Content-Type' => 'application/json' },
      timeout: 5
    }
  end
  
  def login(email, password)
    self.class.post('/api/v1/auth/login', {
      body: { 
        user: { 
          email: email, 
          password: password 
        } 
      }.to_json
    }.merge(@options))
  end
  
  def register(name, email, password, password_confirmation)
    self.class.post('/api/v1/auth/register', {
      body: { 
        user: {
          name: name, 
          email: email, 
          password: password, 
          password_confirmation: password_confirmation 
        }
      }.to_json
    }.merge(@options))
  end
  
  def verify_session(session_token)
    self.class.get('/api/v1/auth/verify', {
      headers: @options[:headers].merge('Authorization' => "Bearer #{session_token}")
    }.merge(@options.except(:headers)))
  end
  
  def logout(session_token)
    self.class.post('/api/v1/auth/logout', {
      headers: @options[:headers].merge('Authorization' => "Bearer #{session_token}")
    }.merge(@options.except(:headers)))
  end
end