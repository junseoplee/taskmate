# TaskMate TDD 개발 가이드라인

Test-Driven Development (TDD) 방법론을 사용한 TaskMate 마이크로서비스 개발 가이드입니다.

## 목표

- **테스트 커버리지**: 최소 80% 이상 (단위 테스트), 70% 이상 (통합 테스트)
- **테스트 실행 시간**: 전체 테스트 스위트 < 30초
- **테스트 안정성**: CI/CD 파이프라인에서 99% 성공률
- **개발 효율성**: TDD 사이클을 통한 버그 조기 발견 및 안전한 리팩토링

## TDD 원칙

### Red-Green-Refactor 사이클

1. **Red**: 실패하는 테스트 작성
2. **Green**: 테스트를 통과하는 최소한의 코드 작성
3. **Refactor**: 코드 품질 개선 (테스트는 여전히 통과)

### 테스트 작성 순서

1. **단위 테스트** (Model, Service 클래스)
2. **컨트롤러 테스트** (API 엔드포인트)
3. **통합 테스트** (서비스 간 통신)
4. **E2E 테스트** (전체 워크플로우)

## 테스트 환경 설정

### 공통 설정 (모든 서비스)

#### Gemfile 설정

```ruby
group :development, :test do
  gem 'rspec-rails', '~> 6.0'
  gem 'factory_bot_rails', '~> 6.2'
  gem 'faker', '~> 3.0'
  gem 'database_cleaner-active_record', '~> 2.1'
  gem 'shoulda-matchers', '~> 5.3'
  gem 'webmock', '~> 3.18'  # HTTP 요청 모킹
  gem 'vcr', '~> 6.1'       # HTTP 응답 기록/재생
  gem 'timecop', '~> 0.9'   # 시간 조작 테스트
end

group :test do
  gem 'simplecov', '~> 0.22', require: false
  gem 'rspec-json_expectations', '~> 2.2'
  gem 'rspec-collection_matchers', '~> 1.2'
end
```

#### RSpec 설정 (.rspec)

```
--require spec_helper
--require rails_helper
--format documentation
--color
--order random
```

#### spec/rails_helper.rb

```ruby
require 'spec_helper'
require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'
require 'database_cleaner/active_record'
require 'webmock/rspec'
require 'vcr'
require 'timecop'

# 테스트 커버리지 설정
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'
  
  add_group 'Models', 'app/models'
  add_group 'Controllers', 'app/controllers'
  add_group 'Services', 'app/services'
  add_group 'Libraries', 'lib'
  
  minimum_coverage 80
end

# WebMock 설정
WebMock.disable_net_connect!(allow_localhost: true)

# VCR 설정
VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = false
end

# Database Cleaner 설정
RSpec.configure do |config|
  config.use_transactional_fixtures = false
  
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, :js => true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
  
  # Timecop 정리
  config.after(:each) do
    Timecop.return
  end
end

# FactoryBot 설정
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

# Shoulda Matchers 설정
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# 공통 헬퍼 메서드
RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
  config.include JsonHelpers, type: :request
end

# JSON 응답 헬퍼
module JsonHelpers
  def json_response
    JSON.parse(response.body)
  end

  def json_response_symbolized
    JSON.parse(response.body, symbolize_names: true)
  end
end
```

## User Service 테스트 전략

### 1. User 모델 테스트

#### spec/models/user_spec.rb

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:sessions).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:user) }
    
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(2).is_at_most(50) }
    it { should have_secure_password }
    it { should validate_length_of(:password).is_at_least(8) }
  end

  describe 'email validation' do
    it 'accepts valid email formats' do
      valid_emails = %w[
        user@example.com
        test.user@domain.co.kr
        user+tag@example.org
      ]
      
      valid_emails.each do |email|
        user = build(:user, email: email)
        expect(user).to be_valid
      end
    end

    it 'rejects invalid email formats' do
      invalid_emails = %w[
        plainaddress
        @missingdomain.com
        missing@.com
        missing.domain@.com
      ]
      
      invalid_emails.each do |email|
        user = build(:user, email: email)
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include('is invalid')
      end
    end
  end

  describe 'password security' do
    let(:user) { create(:user, password: 'SecurePass123!') }

    it 'stores encrypted password' do
      expect(user.password_digest).to be_present
      expect(user.password_digest).not_to eq('SecurePass123!')
    end

    it 'authenticates with correct password' do
      expect(user.authenticate('SecurePass123!')).to eq(user)
    end

    it 'fails authentication with incorrect password' do
      expect(user.authenticate('wrongpassword')).to be_falsey
    end
  end

  describe 'instance methods' do
    let(:user) { create(:user) }

    describe '#full_name' do
      it 'returns the user name' do
        expect(user.full_name).to eq(user.name)
      end
    end

    describe '#active_session' do
      context 'with valid session' do
        let!(:session) { create(:session, user: user, expires_at: 1.hour.from_now) }

        it 'returns the active session' do
          expect(user.active_session).to eq(session)
        end
      end

      context 'without valid session' do
        it 'returns nil' do
          expect(user.active_session).to be_nil
        end
      end
    end
  end
end
```

#### spec/factories/users.rb

```ruby
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { Faker::Name.name }
    password { 'SecurePass123!' }
    password_confirmation { 'SecurePass123!' }
    
    trait :with_session do
      after(:create) do |user|
        create(:session, user: user)
      end
    end
  end
end
```

### 2. Session 모델 테스트

#### spec/models/session_spec.rb

```ruby
require 'rails_helper'

RSpec.describe Session, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:token) }
    it { should validate_uniqueness_of(:token) }
    it { should validate_presence_of(:expires_at) }
  end

  describe 'callbacks' do
    describe 'before_create :generate_token' do
      it 'generates a unique token' do
        session = build(:session, token: nil)
        expect { session.save! }.to change(session, :token).from(nil)
        expect(session.token).to be_present
        expect(session.token.length).to eq(36) # UUID length
      end
    end

    describe 'before_create :set_expiry' do
      it 'sets expiry time to 24 hours from now' do
        Timecop.freeze(Time.current) do
          session = create(:session)
          expect(session.expires_at).to be_within(1.second).of(24.hours.from_now)
        end
      end
    end
  end

  describe 'scopes' do
    let!(:valid_session) { create(:session, expires_at: 1.hour.from_now) }
    let!(:expired_session) { create(:session, expires_at: 1.hour.ago) }

    describe '.valid' do
      it 'returns only non-expired sessions' do
        expect(Session.valid).to include(valid_session)
        expect(Session.valid).not_to include(expired_session)
      end
    end

    describe '.expired' do
      it 'returns only expired sessions' do
        expect(Session.expired).to include(expired_session)
        expect(Session.expired).not_to include(valid_session)
      end
    end
  end

  describe 'instance methods' do
    describe '#valid?' do
      it 'returns true for non-expired session' do
        session = create(:session, expires_at: 1.hour.from_now)
        expect(session.valid_session?).to be true
      end

      it 'returns false for expired session' do
        session = create(:session, expires_at: 1.hour.ago)
        expect(session.valid_session?).to be false
      end
    end

    describe '#extend_expiry!' do
      it 'extends session expiry by 24 hours' do
        session = create(:session)
        original_expiry = session.expires_at
        
        Timecop.freeze(1.hour.from_now) do
          session.extend_expiry!
          expect(session.expires_at).to be > original_expiry
          expect(session.expires_at).to be_within(1.second).of(24.hours.from_now)
        end
      end
    end
  end

  describe 'cleanup' do
    describe '.cleanup_expired' do
      let!(:valid_sessions) { create_list(:session, 3, expires_at: 1.hour.from_now) }
      let!(:expired_sessions) { create_list(:session, 2, expires_at: 1.hour.ago) }

      it 'removes expired sessions only' do
        expect { Session.cleanup_expired }.to change { Session.count }.by(-2)
        expect(Session.all).to match_array(valid_sessions)
      end
    end
  end
end
```

### 3. AuthController 테스트

#### spec/controllers/api/v1/auth_controller_spec.rb

```ruby
require 'rails_helper'

RSpec.describe Api::V1::AuthController, type: :request do
  let(:base_url) { '/api/v1/auth' }
  let(:valid_user) { create(:user) }

  describe 'POST /register' do
    let(:url) { "#{base_url}/register" }
    let(:valid_params) do
      {
        user: {
          email: 'newuser@example.com',
          name: 'New User',
          password: 'SecurePass123!',
          password_confirmation: 'SecurePass123!'
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new user' do
        expect { post url, params: valid_params }.to change { User.count }.by(1)
      end

      it 'creates a session for the user' do
        expect { post url, params: valid_params }.to change { Session.count }.by(1)
      end

      it 'returns success response with user data' do
        post url, params: valid_params
        
        expect(response).to have_http_status(:created)
        expect(json_response).to include(
          'status' => 'success',
          'user' => a_hash_including(
            'id' => be_present,
            'email' => 'newuser@example.com',
            'name' => 'New User'
          ),
          'session_token' => be_present
        )
      end

      it 'sets session cookie' do
        post url, params: valid_params
        expect(response.cookies['session_token']).to be_present
      end
    end

    context 'with invalid parameters' do
      it 'returns error for missing email' do
        invalid_params = valid_params.deep_dup
        invalid_params[:user][:email] = ''
        
        post url, params: invalid_params
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to include(
          'status' => 'error',
          'errors' => a_hash_including('email')
        )
      end

      it 'returns error for duplicate email' do
        create(:user, email: 'duplicate@example.com')
        duplicate_params = valid_params.deep_dup
        duplicate_params[:user][:email] = 'duplicate@example.com'
        
        post url, params: duplicate_params
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to include(
          'status' => 'error',
          'errors' => a_hash_including('email')
        )
      end

      it 'returns error for weak password' do
        weak_params = valid_params.deep_dup
        weak_params[:user][:password] = '123'
        weak_params[:user][:password_confirmation] = '123'
        
        post url, params: weak_params
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to include(
          'status' => 'error',
          'errors' => a_hash_including('password')
        )
      end
    end
  end

  describe 'POST /login' do
    let(:url) { "#{base_url}/login" }
    let(:valid_params) do
      {
        user: {
          email: valid_user.email,
          password: 'SecurePass123!'
        }
      }
    end

    context 'with valid credentials' do
      it 'creates a new session' do
        expect { post url, params: valid_params }.to change { Session.count }.by(1)
      end

      it 'returns success response' do
        post url, params: valid_params
        
        expect(response).to have_http_status(:ok)
        expect(json_response).to include(
          'status' => 'success',
          'user' => a_hash_including(
            'id' => valid_user.id,
            'email' => valid_user.email,
            'name' => valid_user.name
          ),
          'session_token' => be_present
        )
      end

      it 'sets session cookie' do
        post url, params: valid_params
        expect(response.cookies['session_token']).to be_present
      end
    end

    context 'with invalid credentials' do
      it 'returns error for wrong password' do
        wrong_params = valid_params.deep_dup
        wrong_params[:user][:password] = 'wrongpassword'
        
        post url, params: wrong_params
        
        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to include(
          'status' => 'error',
          'message' => 'Invalid email or password'
        )
      end

      it 'returns error for non-existent email' do
        invalid_params = valid_params.deep_dup
        invalid_params[:user][:email] = 'nonexistent@example.com'
        
        post url, params: invalid_params
        
        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to include(
          'status' => 'error',
          'message' => 'Invalid email or password'
        )
      end
    end
  end

  describe 'POST /logout' do
    let(:url) { "#{base_url}/logout" }
    let(:user_with_session) { create(:user, :with_session) }
    let(:session_token) { user_with_session.sessions.first.token }

    context 'with valid session' do
      before do
        cookies['session_token'] = session_token
      end

      it 'destroys the session' do
        expect { post url }.to change { Session.count }.by(-1)
      end

      it 'returns success response' do
        post url
        
        expect(response).to have_http_status(:ok)
        expect(json_response).to include(
          'status' => 'success',
          'message' => 'Logged out successfully'
        )
      end

      it 'clears session cookie' do
        post url
        expect(response.cookies['session_token']).to be_blank
      end
    end

    context 'without valid session' do
      it 'returns unauthorized error' do
        post url
        
        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to include(
          'status' => 'error',
          'message' => 'No active session'
        )
      end
    end
  end

  describe 'GET /verify' do
    let(:url) { "#{base_url}/verify" }
    let(:user_with_session) { create(:user, :with_session) }
    let(:session_token) { user_with_session.sessions.first.token }

    context 'with valid session token' do
      it 'returns user information' do
        get url, headers: { 'Authorization' => "Bearer #{session_token}" }
        
        expect(response).to have_http_status(:ok)
        expect(json_response).to include(
          'status' => 'success',
          'user' => a_hash_including(
            'id' => user_with_session.id,
            'email' => user_with_session.email,
            'name' => user_with_session.name
          ),
          'valid' => true
        )
      end
    end

    context 'with expired session token' do
      let(:expired_session) { create(:session, user: valid_user, expires_at: 1.hour.ago) }

      it 'returns invalid session response' do
        get url, headers: { 'Authorization' => "Bearer #{expired_session.token}" }
        
        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to include(
          'status' => 'error',
          'valid' => false,
          'message' => 'Session expired'
        )
      end
    end

    context 'without session token' do
      it 'returns unauthorized response' do
        get url
        
        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to include(
          'status' => 'error',
          'valid' => false,
          'message' => 'No session token provided'
        )
      end
    end
  end
end
```

## Task Service 테스트 전략

### 1. Task 모델 테스트

#### spec/models/task_spec.rb

```ruby
require 'rails_helper'

RSpec.describe Task, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_least(1).is_at_most(200) }
    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:priority) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(
      pending: 0,
      in_progress: 1, 
      completed: 2,
      cancelled: 3
    )}

    it { should define_enum_for(:priority).with_values(
      low: 0,
      medium: 1,
      high: 2,
      urgent: 3
    )}
  end

  describe 'status transitions' do
    let(:task) { create(:task, status: :pending) }

    it 'allows transition from pending to in_progress' do
      expect { task.update!(status: :in_progress) }.not_to raise_error
      expect(task.reload.status).to eq('in_progress')
    end

    it 'allows transition from in_progress to completed' do
      task.update!(status: :in_progress)
      expect { task.update!(status: :completed) }.not_to raise_error
      expect(task.reload.status).to eq('completed')
    end

    it 'prevents transition from completed to pending' do
      task.update!(status: :completed)
      expect(task).not_to be_valid
    end
  end

  describe 'scopes' do
    let!(:pending_task) { create(:task, status: :pending) }
    let!(:completed_task) { create(:task, status: :completed) }
    let!(:high_priority_task) { create(:task, priority: :high) }
    let!(:overdue_task) { create(:task, due_date: 1.day.ago) }

    describe '.by_status' do
      it 'filters tasks by status' do
        expect(Task.by_status(:pending)).to include(pending_task)
        expect(Task.by_status(:pending)).not_to include(completed_task)
      end
    end

    describe '.by_priority' do
      it 'filters tasks by priority' do
        expect(Task.by_priority(:high)).to include(high_priority_task)
        expect(Task.by_priority(:low)).not_to include(high_priority_task)
      end
    end

    describe '.overdue' do
      it 'returns tasks past their due date' do
        expect(Task.overdue).to include(overdue_task)
        expect(Task.overdue).not_to include(pending_task)
      end
    end
  end

  describe 'instance methods' do
    let(:task) { create(:task, created_at: 2.days.ago, due_date: 1.day.from_now) }

    describe '#overdue?' do
      it 'returns true when past due date' do
        task.update!(due_date: 1.day.ago)
        expect(task.overdue?).to be true
      end

      it 'returns false when within due date' do
        expect(task.overdue?).to be false
      end
    end

    describe '#days_until_due' do
      it 'returns positive number for future due date' do
        expect(task.days_until_due).to eq(1)
      end

      it 'returns negative number for past due date' do
        task.update!(due_date: 1.day.ago)
        expect(task.days_until_due).to eq(-1)
      end
    end
  end
end
```

### 2. User Service 연동 테스트

#### spec/services/auth_service_spec.rb

```ruby
require 'rails_helper'

RSpec.describe AuthService, type: :service do
  let(:service) { described_class.new }
  let(:valid_token) { 'valid-session-token' }
  let(:invalid_token) { 'invalid-session-token' }
  let(:user_data) do
    {
      'id' => 1,
      'email' => 'user@example.com',
      'name' => 'Test User'
    }
  end

  describe '#verify_session' do
    context 'with valid token', :vcr do
      before do
        stub_request(:get, "#{ENV['USER_SERVICE_URL']}/api/v1/auth/verify")
          .with(headers: { 'Authorization' => "Bearer #{valid_token}" })
          .to_return(
            status: 200,
            body: {
              status: 'success',
              user: user_data,
              valid: true
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns user data for valid session' do
        result = service.verify_session(valid_token)
        
        expect(result[:success]).to be true
        expect(result[:user]).to eq(user_data)
      end
    end

    context 'with invalid token' do
      before do
        stub_request(:get, "#{ENV['USER_SERVICE_URL']}/api/v1/auth/verify")
          .with(headers: { 'Authorization' => "Bearer #{invalid_token}" })
          .to_return(
            status: 401,
            body: {
              status: 'error',
              valid: false,
              message: 'Session expired'
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns error for invalid session' do
        result = service.verify_session(invalid_token)
        
        expect(result[:success]).to be false
        expect(result[:error]).to eq('Session expired')
      end
    end

    context 'when User Service is unavailable' do
      before do
        stub_request(:get, "#{ENV['USER_SERVICE_URL']}/api/v1/auth/verify")
          .to_timeout
      end

      it 'returns service unavailable error' do
        result = service.verify_session(valid_token)
        
        expect(result[:success]).to be false
        expect(result[:error]).to match(/service unavailable/i)
      end
    end

    context 'with retry logic' do
      before do
        stub_request(:get, "#{ENV['USER_SERVICE_URL']}/api/v1/auth/verify")
          .to_timeout.times(2).then
          .to_return(
            status: 200,
            body: {
              status: 'success',
              user: user_data,
              valid: true
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'retries on timeout and succeeds' do
        result = service.verify_session(valid_token)
        
        expect(result[:success]).to be true
        expect(result[:user]).to eq(user_data)
      end
    end
  end

  describe '#get_user' do
    let(:user_id) { 1 }

    context 'with valid user ID' do
      before do
        stub_request(:get, "#{ENV['USER_SERVICE_URL']}/api/v1/users/#{user_id}")
          .to_return(
            status: 200,
            body: {
              status: 'success',
              user: user_data
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns user data' do
        result = service.get_user(user_id)
        
        expect(result[:success]).to be true
        expect(result[:user]).to eq(user_data)
      end
    end

    context 'with non-existent user ID' do
      before do
        stub_request(:get, "#{ENV['USER_SERVICE_URL']}/api/v1/users/999")
          .to_return(
            status: 404,
            body: {
              status: 'error',
              message: 'User not found'
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns not found error' do
        result = service.get_user(999)
        
        expect(result[:success]).to be false
        expect(result[:error]).to eq('User not found')
      end
    end
  end
end
```

## 통합 테스트 전략

### 1. 서비스 간 통신 테스트

#### spec/integration/auth_flow_spec.rb

```ruby
require 'rails_helper'

RSpec.describe 'Authentication Flow Integration', type: :request do
  let(:user_service_url) { ENV['USER_SERVICE_URL'] }
  let(:task_service_url) { ENV['TASK_SERVICE_URL'] }

  describe 'Complete user journey' do
    let(:user_data) do
      {
        email: 'integration@example.com',
        name: 'Integration User',
        password: 'SecurePass123!',
        password_confirmation: 'SecurePass123!'
      }
    end

    it 'allows user to register, login, and create tasks' do
      # Step 1: User registration
      post "#{user_service_url}/api/v1/auth/register", params: { user: user_data }
      
      expect(response).to have_http_status(:created)
      session_token = json_response['session_token']
      expect(session_token).to be_present

      # Step 2: Create a task using the session token
      task_data = {
        task: {
          title: 'Integration Test Task',
          description: 'Created during integration test',
          priority: 'high',
          due_date: 1.week.from_now
        }
      }

      post "#{task_service_url}/api/v1/tasks", 
           params: task_data,
           headers: { 'Authorization' => "Bearer #{session_token}" }

      expect(response).to have_http_status(:created)
      expect(json_response['task']['title']).to eq('Integration Test Task')

      # Step 3: Verify task belongs to authenticated user
      get "#{task_service_url}/api/v1/tasks",
          headers: { 'Authorization' => "Bearer #{session_token}" }

      expect(response).to have_http_status(:ok)
      expect(json_response['tasks']).to have(1).item
      expect(json_response['tasks'][0]['title']).to eq('Integration Test Task')

      # Step 4: Logout
      post "#{user_service_url}/api/v1/auth/logout",
           headers: { 'Authorization' => "Bearer #{session_token}" }

      expect(response).to have_http_status(:ok)

      # Step 5: Verify session is invalidated
      get "#{task_service_url}/api/v1/tasks",
          headers: { 'Authorization' => "Bearer #{session_token}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'Error handling scenarios' do
    it 'handles User Service unavailability gracefully' do
      # Simulate User Service being down
      allow(AuthService).to receive(:new).and_return(
        double(verify_session: { success: false, error: 'Service unavailable' })
      )

      get "#{task_service_url}/api/v1/tasks",
          headers: { 'Authorization' => 'Bearer some-token' }

      expect(response).to have_http_status(:service_unavailable)
      expect(json_response['error']).to match(/service unavailable/i)
    end

    it 'handles network timeouts with proper retries' do
      # Mock timeout and recovery
      call_count = 0
      allow_any_instance_of(AuthService).to receive(:verify_session) do
        call_count += 1
        if call_count <= 2
          raise Net::TimeoutError
        else
          { success: true, user: { 'id' => 1, 'email' => 'test@example.com' } }
        end
      end

      get "#{task_service_url}/api/v1/tasks",
          headers: { 'Authorization' => 'Bearer valid-token' }

      expect(response).to have_http_status(:ok)
      expect(call_count).to eq(3) # 2 failures + 1 success
    end
  end
end
```

## 성능 테스트

### 1. 응답 시간 테스트

#### spec/performance/api_performance_spec.rb

```ruby
require 'rails_helper'
require 'benchmark'

RSpec.describe 'API Performance', type: :request do
  let(:user) { create(:user, :with_session) }
  let(:session_token) { user.sessions.first.token }

  describe 'API response times' do
    it 'responds to auth verification within 100ms' do
      time = Benchmark.realtime do
        get '/api/v1/auth/verify', headers: { 'Authorization' => "Bearer #{session_token}" }
      end

      expect(response).to have_http_status(:ok)
      expect(time).to be < 0.1 # 100ms
    end

    it 'responds to task listing within 200ms' do
      create_list(:task, 50, user_id: user.id)

      time = Benchmark.realtime do
        get '/api/v1/tasks', headers: { 'Authorization' => "Bearer #{session_token}" }
      end

      expect(response).to have_http_status(:ok)
      expect(time).to be < 0.2 # 200ms
    end

    it 'handles concurrent requests efficiently' do
      threads = []
      response_times = []

      10.times do
        threads << Thread.new do
          time = Benchmark.realtime do
            get '/api/v1/tasks', headers: { 'Authorization' => "Bearer #{session_token}" }
          end
          response_times << time
        end
      end

      threads.each(&:join)
      
      average_time = response_times.sum / response_times.size
      expect(average_time).to be < 0.3 # 300ms average for concurrent requests
    end
  end
end
```

## CI/CD 통합

### GitHub Actions 설정

#### .github/workflows/test.yml

```yaml
name: Test Suite

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: taskmate
          POSTGRES_PASSWORD: password
          POSTGRES_DB: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379

    strategy:
      matrix:
        service: [user-service, task-service]

    steps:
    - uses: actions/checkout@v4

    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: 3.4.3
        bundler-cache: true
        working-directory: ./services/${{ matrix.service }}

    - name: Setup test database
      working-directory: ./services/${{ matrix.service }}
      env:
        RAILS_ENV: test
        DATABASE_URL: postgresql://taskmate:password@localhost:5432/${{ matrix.service }}_test
        REDIS_URL: redis://localhost:6379/0
      run: |
        bundle exec rails db:create
        bundle exec rails db:migrate

    - name: Run tests
      working-directory: ./services/${{ matrix.service }}
      env:
        RAILS_ENV: test
        DATABASE_URL: postgresql://taskmate:password@localhost:5432/${{ matrix.service }}_test
        REDIS_URL: redis://localhost:6379/0
      run: |
        bundle exec rspec --format RspecJunitFormatter --out tmp/rspec.xml --format progress

    - name: Upload test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: test-results-${{ matrix.service }}
        path: ./services/${{ matrix.service }}/tmp/rspec.xml

    - name: Upload coverage reports
      uses: codecov/codecov-action@v3
      with:
        file: ./services/${{ matrix.service }}/coverage/.resultset.json
        flags: ${{ matrix.service }}
```

## 테스트 실행 스크립트

### scripts/run-tests.sh

```bash
#!/bin/bash

set -e

SERVICE=${1:-all}
ENVIRONMENT=${2:-test}

echo "🧪 Running tests for: $SERVICE"

run_service_tests() {
    local service=$1
    echo "Testing $service..."
    
    cd "services/$service"
    
    # 환경 설정
    export RAILS_ENV=$ENVIRONMENT
    export DATABASE_URL="postgresql://taskmate:password@localhost:5432/${service}_${ENVIRONMENT}"
    export REDIS_URL="redis://localhost:6379/0"
    
    # 의존성 설치
    bundle install --quiet
    
    # 데이터베이스 설정
    bundle exec rails db:create db:migrate
    
    # 테스트 실행
    bundle exec rspec \
        --format documentation \
        --format RspecJunitFormatter \
        --out "tmp/rspec_${service}.xml" \
        --order random
    
    echo "✅ $service tests completed"
    cd - > /dev/null
}

if [ "$SERVICE" = "all" ]; then
    echo "🔄 Running all service tests..."
    
    # 병렬 실행
    run_service_tests "user-service" &
    USER_PID=$!
    
    run_service_tests "task-service" &
    TASK_PID=$!
    
    # 모든 테스트 완료 대기
    wait $USER_PID
    wait $TASK_PID
    
    echo "🎉 All tests completed!"
    
    # 통합 테스트 실행
    echo "🔗 Running integration tests..."
    cd integration-tests
    bundle exec rspec
    
else
    run_service_tests "$SERVICE"
fi

# 테스트 결과 요약
echo "📊 Test Results Summary:"
find . -name "rspec_*.xml" -exec echo "- {}" \;

# 커버리지 리포트
echo "📈 Coverage Reports:"
find . -path "*/coverage/index.html" -exec echo "- file://$PWD/{}" \;
```

## 모니터링 및 메트릭

### 테스트 성능 추적

#### spec/support/performance_tracker.rb

```ruby
class PerformanceTracker
  def self.track(test_name, &block)
    start_time = Time.now
    memory_before = `ps -o rss= -p #{Process.pid}`.to_i
    
    result = yield
    
    end_time = Time.now
    memory_after = `ps -o rss= -p #{Process.pid}`.to_i
    
    duration = end_time - start_time
    memory_used = memory_after - memory_before
    
    Rails.logger.info({
      test: test_name,
      duration: duration.round(3),
      memory_delta: memory_used,
      timestamp: end_time.iso8601
    }.to_json)
    
    # 성능 임계값 검사
    warn_if_slow(test_name, duration)
    warn_if_memory_heavy(test_name, memory_used)
    
    result
  end

  private

  def self.warn_if_slow(test_name, duration)
    if duration > 5.0 # 5초 이상
      puts "⚠️  SLOW TEST: #{test_name} took #{duration.round(2)}s"
    end
  end

  def self.warn_if_memory_heavy(test_name, memory_used)
    if memory_used > 50_000 # 50MB 이상
      puts "⚠️  MEMORY HEAVY: #{test_name} used #{memory_used}KB"
    end
  end
end

# 사용법:
# PerformanceTracker.track("User creation") do
#   create(:user)
# end
```

## 베스트 프랙티스

### 1. 테스트 격리

- **Database Cleaner**: 각 테스트 간 데이터베이스 상태 초기화
- **WebMock**: 외부 API 호출 모킹으로 테스트 격리
- **Timecop**: 시간 의존적 테스트의 일관성 보장

### 2. 테스트 데이터 관리

- **FactoryBot**: 일관된 테스트 데이터 생성
- **Faker**: 현실적인 더미 데이터
- **Traits**: 다양한 객체 상태 정의

### 3. 테스트 성능 최적화

- **Parallel execution**: 서비스별 병렬 테스트 실행
- **Selective running**: 변경된 파일 관련 테스트만 실행
- **Database optimization**: 트랜잭션 기반 빠른 롤백

### 4. 에러 처리 테스트

- **Network failures**: 타임아웃, 연결 실패 시나리오
- **Service unavailability**: 의존성 서비스 다운 상황
- **Data corruption**: 잘못된 데이터 형식 처리

### 5. 보안 테스트

- **Authentication bypass**: 인증 우회 시도 테스트
- **Authorization**: 권한 없는 리소스 접근 테스트
- **Input validation**: SQL Injection, XSS 방어 테스트

## 다음 단계

1. **User Service 구현**: TDD 사이클로 인증 시스템 개발
2. **Task Service 구현**: 태스크 CRUD 및 서비스 연동
3. **통합 테스트**: 서비스 간 통신 검증
4. **성능 테스트**: 응답 시간 및 동시성 테스트
5. **E2E 테스트**: 전체 사용자 워크플로우 검증

이 가이드라인을 따라 개발하면 안정적이고 유지보수 가능한 마이크로서비스를 구축할 수 있습니다.