# TaskMate Phase 2 실행 계획서

Phase 2: User Service + Task Service TDD 기반 구현 계획

## 📋 개요

### 목표
- TDD 방법론을 사용한 User Service와 Task Service 구현
- 세션 기반 인증 시스템 구축
- 마이크로서비스 간 안전한 통신 구현
- 테스트 커버리지 80% 이상 달성

### 전제 조건
- ✅ Phase 1 완료: Docker 인프라 구성
- ✅ PostgreSQL 멀티 데이터베이스 설정
- ✅ Redis 세션 스토어 설정
- ✅ 개발 환경 스크립트 준비

### 예상 소요 시간
- **총 소요 시간**: 8-10일
- **User Service**: 4-5일
- **Task Service**: 3-4일
- **통합 및 테스트**: 1-2일

## 🏗️ User Service 구현 계획

### 1단계: 프로젝트 초기화 (반나절)

#### 체크리스트
- [ ] Rails API 프로젝트 생성
  ```bash
  cd services/user-service
  rails new . --api --database=postgresql --skip-test --skip-action-mailbox --skip-action-text --skip-active-storage
  ```
- [ ] Gemfile 설정
  ```ruby
  # 프로덕션 gem
  gem 'bcrypt', '~> 3.1.7'
  gem 'redis', '~> 5.0'
  gem 'rack-cors'
  gem 'bootsnap', '>= 1.4.4', require: false
  
  # 개발/테스트 gem
  group :development, :test do
    gem 'rspec-rails', '~> 6.0'
    gem 'factory_bot_rails', '~> 6.2'
    gem 'faker', '~> 3.0'
    gem 'database_cleaner-active_record', '~> 2.1'
    gem 'shoulda-matchers', '~> 5.3'
    gem 'webmock', '~> 3.18'
    gem 'pry-rails'
  end
  
  group :test do
    gem 'simplecov', '~> 0.22', require: false
    gem 'rspec-json_expectations', '~> 2.2'
  end
  ```
- [ ] 기본 설정 파일 구성
- [ ] RSpec 테스트 환경 설정
- [ ] Docker 설정 확인

#### 예상 결과
- Rails API 프로젝트 구조 완성
- 테스트 환경 실행 가능
- `rails server -p 3000` 정상 실행

### 2단계: User 모델 TDD 구현 (1일)

#### TDD 사이클

**Red Phase: 실패하는 테스트 작성**

```ruby
# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }
    
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:name) }
    it { should have_secure_password }
  end

  describe 'email validation' do
    it 'accepts valid email formats' do
      valid_emails = %w[user@example.com test.user@domain.co.kr]
      valid_emails.each do |email|
        user = build(:user, email: email)
        expect(user).to be_valid
      end
    end

    it 'rejects invalid email formats' do
      invalid_emails = %w[plainaddress @missingdomain.com]
      invalid_emails.each do |email|
        user = build(:user, email: email)
        expect(user).not_to be_valid
      end
    end
  end
end
```

**Green Phase: 테스트 통과 코드 작성**

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password
  
  validates :email, presence: true, 
                   uniqueness: { case_sensitive: false },
                   format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :password, length: { minimum: 8 }, if: :password_required?
  
  has_many :sessions, dependent: :destroy

  private

  def password_required?
    new_record? || password.present?
  end
end
```

**Refactor Phase: 코드 개선**

#### 체크리스트
- [ ] User 모델 마이그레이션 생성
  ```ruby
  # db/migrate/xxx_create_users.rb
  class CreateUsers < ActiveRecord::Migration[8.0]
    def change
      create_table :users do |t|
        t.string :email, null: false
        t.string :password_digest, null: false
        t.string :name, null: false
        t.timestamps
      end
      
      add_index :users, :email, unique: true
    end
  end
  ```
- [ ] User 팩토리 생성
  ```ruby
  # spec/factories/users.rb
  FactoryBot.define do
    factory :user do
      sequence(:email) { |n| "user#{n}@example.com" }
      name { Faker::Name.name }
      password { 'SecurePass123!' }
      password_confirmation { 'SecurePass123!' }
    end
  end
  ```
- [ ] 유효성 검증 테스트 (이메일, 패스워드, 이름)
- [ ] 비즈니스 로직 메서드 구현

#### 예상 결과
- User 모델 테스트 100% 통과
- 이메일 유효성 검증 완료
- BCrypt 패스워드 암호화 적용

### 3단계: Session 모델 TDD 구현 (1일)

#### TDD 사이클

**Red Phase: Session 테스트 작성**

```ruby
# spec/models/session_spec.rb
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
    it 'generates token before creation' do
      session = build(:session, token: nil)
      session.save!
      expect(session.token).to be_present
      expect(session.token.length).to eq(36) # UUID format
    end

    it 'sets expiry to 24 hours from now' do
      Timecop.freeze(Time.current) do
        session = create(:session)
        expect(session.expires_at).to be_within(1.second).of(24.hours.from_now)
      end
    end
  end
end
```

**Green Phase: Session 모델 구현**

```ruby
# app/models/session.rb
class Session < ApplicationRecord
  belongs_to :user
  
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true
  
  before_create :generate_token, :set_expiry
  
  scope :valid, -> { where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }

  def valid_session?
    expires_at > Time.current
  end

  def extend_expiry!
    update!(expires_at: 24.hours.from_now)
  end

  def self.cleanup_expired
    expired.delete_all
  end

  private

  def generate_token
    self.token = SecureRandom.uuid
  end

  def set_expiry
    self.expires_at = 24.hours.from_now
  end
end
```

#### 체크리스트
- [ ] Session 마이그레이션 생성
  ```ruby
  # db/migrate/xxx_create_sessions.rb
  class CreateSessions < ActiveRecord::Migration[8.0]
    def change
      create_table :sessions do |t|
        t.references :user, null: false, foreign_key: true
        t.string :token, null: false
        t.datetime :expires_at, null: false
        t.timestamps
      end
      
      add_index :sessions, :token, unique: true
      add_index :sessions, :expires_at
    end
  end
  ```
- [ ] Session 팩토리 생성
- [ ] 토큰 생성 로직 테스트
- [ ] 세션 만료 로직 테스트
- [ ] 세션 정리 배치 작업 테스트

#### 예상 결과
- Session 모델 테스트 100% 통과
- UUID 기반 토큰 생성
- 자동 만료 시간 설정

### 4단계: AuthController TDD 구현 (1.5일)

#### TDD 사이클 - 회원가입 API

**Red Phase: 회원가입 테스트**

```ruby
# spec/requests/api/v1/auth_controller_spec.rb
RSpec.describe 'Api::V1::AuthController', type: :request do
  describe 'POST /api/v1/auth/register' do
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
        expect { post '/api/v1/auth/register', params: valid_params }
          .to change { User.count }.by(1)
      end

      it 'creates a session for the user' do
        expect { post '/api/v1/auth/register', params: valid_params }
          .to change { Session.count }.by(1)
      end

      it 'returns success response with user data' do
        post '/api/v1/auth/register', params: valid_params
        
        expect(response).to have_http_status(:created)
        expect(json_response).to include(
          'status' => 'success',
          'user' => a_hash_including('email', 'name'),
          'session_token' => be_present
        )
      end
    end
  end
end
```

**Green Phase: AuthController 구현**

```ruby
# app/controllers/api/v1/auth_controller.rb
class Api::V1::AuthController < ApplicationController
  def register
    user = User.new(user_params)
    
    if user.save
      session = user.sessions.create!
      
      render json: {
        status: 'success',
        user: user_data(user),
        session_token: session.token
      }, status: :created
    else
      render json: {
        status: 'error',
        errors: user.errors
      }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :name, :password, :password_confirmation)
  end

  def user_data(user)
    {
      id: user.id,
      email: user.email,
      name: user.name
    }
  end
end
```

#### 체크리스트
- [ ] 라우팅 설정
  ```ruby
  # config/routes.rb
  Rails.application.routes.draw do
    namespace :api do
      namespace :v1 do
        namespace :auth do
          post 'register'
          post 'login'
          post 'logout'
          get 'verify'
        end
      end
    end
  end
  ```
- [ ] 회원가입 API 테스트 및 구현
- [ ] 로그인 API 테스트 및 구현
- [ ] 로그아웃 API 테스트 및 구현
- [ ] 세션 검증 API 테스트 및 구현
- [ ] 에러 처리 및 응답 형식 표준화
- [ ] CORS 설정

#### 예상 결과
- 4개 인증 API 엔드포인트 완성
- JSON 응답 형식 통일
- 세션 기반 인증 플로우 완성

### 5단계: UsersController 및 미들웨어 (1일)

#### 체크리스트
- [ ] 인증 미들웨어 구현
  ```ruby
  # app/controllers/concerns/authenticatable.rb
  module Authenticatable
    extend ActiveSupport::Concern

    def authenticate_user!
      token = extract_token
      return unauthorized_response unless token

      session = Session.find_by(token: token)
      return unauthorized_response unless session&.valid_session?

      @current_user = session.user
      session.extend_expiry!
    end

    private

    def extract_token
      header = request.headers['Authorization']
      return unless header

      header.split(' ').last
    end

    def unauthorized_response
      render json: { status: 'error', message: 'Unauthorized' }, status: :unauthorized
    end
  end
  ```
- [ ] UsersController 구현
- [ ] 프로필 조회/수정 API
- [ ] 헬스체크 엔드포인트
- [ ] API 응답 형식 표준화

#### 예상 결과
- 사용자 프로필 관리 기능
- 인증 미들웨어 완성
- 다른 서비스에서 사용할 인증 검증 API

### 6단계: User Service 통합 테스트 (0.5일)

#### 체크리스트
- [ ] 전체 인증 플로우 테스트
  ```ruby
  # spec/integration/auth_flow_spec.rb
  RSpec.describe 'Authentication Flow', type: :request do
    it 'supports complete user journey' do
      # 회원가입
      post '/api/v1/auth/register', params: user_params
      expect(response).to have_http_status(:created)
      
      token = json_response['session_token']
      
      # 프로필 조회
      get '/api/v1/users/profile', headers: auth_headers(token)
      expect(response).to have_http_status(:ok)
      
      # 로그아웃
      post '/api/v1/auth/logout', headers: auth_headers(token)
      expect(response).to have_http_status(:ok)
    end
  end
  ```
- [ ] 에러 시나리오 테스트
- [ ] 성능 테스트 기본 설정
- [ ] Docker 컨테이너 테스트

## 🚀 Task Service 구현 계획

### 1단계: 프로젝트 초기화 (반나절)

#### 체크리스트
- [ ] Rails API 프로젝트 생성
- [ ] User Service 연동을 위한 gem 추가
  ```ruby
  # Task Service Gemfile 추가 항목
  gem 'httparty', '~> 0.21'
  gem 'redis', '~> 5.0'
  gem 'circuit_breaker', '~> 1.1'
  ```
- [ ] RSpec 테스트 환경 설정 (WebMock 포함)
- [ ] 환경변수 설정
  ```bash
  # .env.development
  USER_SERVICE_URL=http://localhost:3000
  DATABASE_URL=postgresql://taskmate:password@localhost:5432/task_service_development
  REDIS_URL=redis://localhost:6379/1
  ```

### 2단계: Task 모델 TDD 구현 (1일)

#### TDD 사이클

**Red Phase: Task 모델 테스트**

```ruby
# spec/models/task_spec.rb
RSpec.describe Task, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_most(200) }
    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:priority) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(
      pending: 0, in_progress: 1, completed: 2, cancelled: 3
    )}
    
    it { should define_enum_for(:priority).with_values(
      low: 0, medium: 1, high: 2, urgent: 3
    )}
  end

  describe 'business logic' do
    it 'prevents completed tasks from changing status' do
      task = create(:task, status: :completed)
      task.status = :pending
      expect(task).not_to be_valid
    end
  end
end
```

**Green Phase: Task 모델 구현**

```ruby
# app/models/task.rb
class Task < ApplicationRecord
  validates :title, presence: true, length: { maximum: 200 }
  validates :description, length: { maximum: 2000 }
  validates :user_id, presence: true
  validates :status, presence: true
  validates :priority, presence: true

  enum status: { pending: 0, in_progress: 1, completed: 2, cancelled: 3 }
  enum priority: { low: 0, medium: 1, high: 2, urgent: 3 }

  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :overdue, -> { where('due_date < ?', Time.current) }

  def overdue?
    due_date && due_date < Time.current
  end

  def days_until_due
    return nil unless due_date
    (due_date.to_date - Date.current).to_i
  end

  private

  def prevent_completed_status_change
    return unless status_changed? && status_was == 'completed'
    errors.add(:status, 'cannot be changed once completed')
  end
end
```

#### 체크리스트
- [ ] Task 마이그레이션 생성
  ```ruby
  # db/migrate/xxx_create_tasks.rb
  class CreateTasks < ActiveRecord::Migration[8.0]
    def change
      create_table :tasks do |t|
        t.string :title, null: false
        t.text :description
        t.integer :status, default: 0, null: false
        t.integer :priority, default: 1, null: false
        t.datetime :due_date
        t.integer :user_id, null: false
        t.timestamps
      end
      
      add_index :tasks, :user_id
      add_index :tasks, :status
      add_index :tasks, :priority
      add_index :tasks, :due_date
    end
  end
  ```
- [ ] Task 팩토리 생성
- [ ] 상태 전환 로직 테스트
- [ ] 비즈니스 로직 메서드 구현

### 3단계: User Service 연동 모듈 TDD 구현 (1일)

#### TDD 사이클

**Red Phase: AuthService 테스트**

```ruby
# spec/services/auth_service_spec.rb
RSpec.describe AuthService, type: :service do
  let(:service) { described_class.new }
  let(:valid_token) { 'valid-session-token' }

  describe '#verify_session' do
    context 'with valid token' do
      before do
        stub_request(:get, "#{ENV['USER_SERVICE_URL']}/api/v1/auth/verify")
          .with(headers: { 'Authorization' => "Bearer #{valid_token}" })
          .to_return(
            status: 200,
            body: { status: 'success', user: { id: 1, email: 'test@example.com' } }.to_json
          )
      end

      it 'returns user data for valid session' do
        result = service.verify_session(valid_token)
        expect(result[:success]).to be true
        expect(result[:user]).to include('id' => 1)
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
  end
end
```

**Green Phase: AuthService 구현**

```ruby
# app/services/auth_service.rb
class AuthService
  include HTTParty
  
  base_uri ENV['USER_SERVICE_URL']
  default_timeout 5

  def initialize
    @circuit_breaker = CircuitBreaker.new(
      failure_threshold: 3,
      recovery_timeout: 30,
      expected_errors: [Net::TimeoutError, Errno::ECONNREFUSED]
    )
  end

  def verify_session(token)
    @circuit_breaker.call do
      response = self.class.get(
        '/api/v1/auth/verify',
        headers: { 'Authorization' => "Bearer #{token}" },
        timeout: 5
      )

      if response.success?
        { success: true, user: response.parsed_response['user'] }
      else
        { success: false, error: response.parsed_response['message'] || 'Invalid session' }
      end
    end
  rescue Net::TimeoutError, Errno::ECONNREFUSED => e
    { success: false, error: 'User service unavailable' }
  rescue CircuitBreaker::OpenError
    { success: false, error: 'User service circuit breaker open' }
  end

  def get_user(user_id)
    @circuit_breaker.call do
      response = self.class.get(
        "/api/v1/users/#{user_id}",
        timeout: 5
      )

      if response.success?
        { success: true, user: response.parsed_response['user'] }
      else
        { success: false, error: response.parsed_response['message'] || 'User not found' }
      end
    end
  rescue StandardError => e
    { success: false, error: 'User service error' }
  end
end
```

#### 체크리스트
- [ ] HTTParty 기반 HTTP 클라이언트 구현
- [ ] Circuit Breaker 패턴 적용
- [ ] 재시도 로직 구현
- [ ] 타임아웃 및 에러 처리
- [ ] WebMock을 사용한 외부 API 테스트

### 4단계: TasksController TDD 구현 (1일)

#### 체크리스트
- [ ] 인증 미들웨어 구현 (User Service 연동)
  ```ruby
  # app/controllers/concerns/authenticatable.rb
  module Authenticatable
    def authenticate_user!
      token = extract_token
      return unauthorized_response unless token

      auth_result = AuthService.new.verify_session(token)
      return service_unavailable_response unless auth_result[:success]

      @current_user_id = auth_result[:user]['id']
      @current_user_data = auth_result[:user]
    end

    private

    def extract_token
      header = request.headers['Authorization']
      header&.split(' ')&.last
    end

    def unauthorized_response
      render json: { status: 'error', message: 'Unauthorized' }, status: :unauthorized
    end

    def service_unavailable_response
      render json: { status: 'error', message: 'Authentication service unavailable' }, 
             status: :service_unavailable
    end
  end
  ```
- [ ] TasksController CRUD API 구현
  ```ruby
  # app/controllers/api/v1/tasks_controller.rb
  class Api::V1::TasksController < ApplicationController
    include Authenticatable
    
    before_action :authenticate_user!
    before_action :set_task, only: [:show, :update, :destroy]

    def index
      tasks = Task.by_user(@current_user_id)
                  .by_status(params[:status]) if params[:status]
                  .by_priority(params[:priority]) if params[:priority]
                  .page(params[:page])

      render json: {
        status: 'success',
        tasks: tasks.map { |task| task_data(task) },
        pagination: pagination_data(tasks)
      }
    end

    def create
      task = Task.new(task_params.merge(user_id: @current_user_id))
      
      if task.save
        render json: {
          status: 'success',
          task: task_data(task)
        }, status: :created
      else
        render json: {
          status: 'error',
          errors: task.errors
        }, status: :unprocessable_entity
      end
    end

    private

    def task_params
      params.require(:task).permit(:title, :description, :priority, :due_date)
    end

    def task_data(task)
      {
        id: task.id,
        title: task.title,
        description: task.description,
        status: task.status,
        priority: task.priority,
        due_date: task.due_date,
        created_at: task.created_at,
        updated_at: task.updated_at
      }
    end
  end
  ```
- [ ] 모든 CRUD 엔드포인트 TDD 구현
- [ ] 페이징 및 필터링 기능
- [ ] 권한 검증 (본인 태스크만 접근)

### 5단계: Task Service 통합 테스트 (0.5일)

#### 체크리스트
- [ ] 서비스 간 통신 테스트
  ```ruby
  # spec/integration/user_service_integration_spec.rb
  RSpec.describe 'User Service Integration', type: :request do
    before do
      # User Service 모킹
      stub_request(:get, "#{ENV['USER_SERVICE_URL']}/api/v1/auth/verify")
        .to_return(
          status: 200,
          body: { status: 'success', user: { id: 1, email: 'test@example.com' } }.to_json
        )
    end

    it 'creates task with valid authentication' do
      post '/api/v1/tasks',
           params: { task: { title: 'Test Task', priority: 'high' } },
           headers: { 'Authorization' => 'Bearer valid-token' }

      expect(response).to have_http_status(:created)
      expect(json_response['task']['title']).to eq('Test Task')
    end
  end
  ```
- [ ] 에러 시나리오 테스트 (User Service 다운, 네트워크 오류)
- [ ] 성능 테스트
- [ ] Docker 컨테이너 테스트

## 🔗 서비스 간 통신 및 통합

### 1단계: API 클라이언트 라이브러리 (0.5일)

#### 체크리스트
- [ ] BaseClient 클래스 구현
  ```ruby
  # lib/api_clients/base_client.rb
  class ApiClients::BaseClient
    include HTTParty
    
    attr_reader :base_uri, :timeout, :retries

    def initialize(base_uri:, timeout: 5, retries: 3)
      @base_uri = base_uri
      @timeout = timeout
      @retries = retries
      
      self.class.base_uri @base_uri
      self.class.default_timeout @timeout
    end

    def get_with_retry(path, options = {})
      with_retry do
        self.class.get(path, options)
      end
    end

    def post_with_retry(path, options = {})
      with_retry do
        self.class.post(path, options)
      end
    end

    private

    def with_retry
      attempts = 0
      begin
        attempts += 1
        yield
      rescue Net::TimeoutError, Errno::ECONNREFUSED => e
        if attempts <= @retries
          sleep(2 ** attempts) # Exponential backoff
          retry
        else
          raise e
        end
      end
    end
  end
  ```
- [ ] UserServiceClient 구현
- [ ] 연결 풀링 및 타임아웃 설정
- [ ] 에러 처리 및 재시도 로직

### 2단계: 로깅 시스템 구성 (0.5일)

#### 체크리스트
- [ ] 구조화된 JSON 로깅 설정
  ```ruby
  # config/initializers/logging.rb
  Rails.application.configure do
    # JSON 형식 로깅
    config.log_formatter = proc do |severity, timestamp, progname, msg|
      {
        timestamp: timestamp.iso8601,
        severity: severity,
        service: 'user-service', # or 'task-service'
        message: msg,
        process_id: Process.pid,
        thread_id: Thread.current.object_id
      }.to_json + "\n"
    end
  end
  ```
- [ ] 요청 추적 ID (correlation ID) 구현
- [ ] 성능 메트릭 로깅
- [ ] 에러 로깅 표준화

### 3단계: 헬스체크 및 모니터링 (0.5일)

#### 체크리스트
- [ ] 헬스체크 엔드포인트 구현
  ```ruby
  # app/controllers/health_controller.rb
  class HealthController < ApplicationController
    def show
      health_status = {
        service: Rails.application.class.module_parent_name.downcase,
        status: 'healthy',
        timestamp: Time.current.iso8601,
        version: ENV['APP_VERSION'] || '1.0.0',
        dependencies: check_dependencies
      }

      if all_dependencies_healthy?(health_status[:dependencies])
        render json: health_status, status: :ok
      else
        health_status[:status] = 'degraded'
        render json: health_status, status: :service_unavailable
      end
    end

    private

    def check_dependencies
      {
        database: check_database,
        redis: check_redis,
        user_service: check_user_service # Task Service에서만
      }
    end

    def check_database
      ActiveRecord::Base.connection.execute('SELECT 1')
      { status: 'healthy', response_time: measure_response_time { ActiveRecord::Base.connection.execute('SELECT 1') } }
    rescue StandardError => e
      { status: 'unhealthy', error: e.message }
    end

    def check_redis
      Redis.current.ping
      { status: 'healthy', response_time: measure_response_time { Redis.current.ping } }
    rescue StandardError => e
      { status: 'unhealthy', error: e.message }
    end
  end
  ```
- [ ] 의존성 서비스 상태 확인
- [ ] Kubernetes 프로브 호환성

## 📊 테스트 및 품질 보증

### 테스트 실행 계획

#### 단위 테스트 (매일)
```bash
# 각 서비스별 테스트 실행
cd services/user-service
bundle exec rspec spec/models/ spec/services/

cd services/task-service  
bundle exec rspec spec/models/ spec/services/
```

#### 통합 테스트 (주 2회)
```bash
# 서비스 간 통신 테스트
cd services/task-service
bundle exec rspec spec/integration/

# E2E 테스트
cd integration-tests
bundle exec rspec
```

#### 성능 테스트 (주 1회)
```bash
# API 응답 시간 테스트
bundle exec rspec spec/performance/
```

### 품질 체크리스트

#### 코드 품질
- [ ] RuboCop 정적 분석 통과
- [ ] Brakeman 보안 스캔 통과
- [ ] 테스트 커버리지 80% 이상
- [ ] API 응답 시간 < 200ms

#### 보안
- [ ] 인증 우회 시도 방어
- [ ] SQL Injection 방어 확인
- [ ] 민감 정보 로깅 방지
- [ ] HTTPS 강제 설정

#### 운영 준비도
- [ ] 환경변수 기반 설정
- [ ] 로그 레벨 조정 가능
- [ ] Graceful shutdown 구현
- [ ] 헬스체크 엔드포인트 정상 동작

## 🚨 리스크 관리

### 주요 리스크 및 대응 방안

#### 기술적 리스크
1. **서비스 간 통신 장애**
   - 대응: Circuit Breaker 패턴, 재시도 로직
   - 모니터링: 응답 시간, 에러율 추적

2. **데이터베이스 성능**
   - 대응: 인덱스 최적화, 쿼리 튜닝
   - 모니터링: 슬로우 쿼리 로그

3. **세션 관리 복잡성**
   - 대응: Redis 기반 세션 스토어, TTL 관리
   - 테스트: 세션 만료 시나리오 철저히 테스트

#### 일정 리스크
1. **TDD 사이클 준수로 인한 초기 지연**
   - 대응: 작은 단위로 빠른 iteration
   - 모니터링: 일일 진행 상황 체크

2. **서비스 간 의존성으로 인한 블로킹**
   - 대응: Mock/Stub 활용으로 독립적 개발
   - 계획: User Service 우선 완성 후 Task Service 착수

### 비상 계획

#### Phase 2 목표 축소 시나리오
1. **최소 기능 구현** (6일 내 완성)
   - User Service: 기본 인증만 (회원가입, 로그인, 검증)
   - Task Service: 기본 CRUD만
   - 테스트 커버리지: 70% 이상

2. **고급 기능 제외**
   - Circuit Breaker 패턴 → 단순 타임아웃
   - 상세한 에러 처리 → 기본 HTTP 상태 코드
   - 성능 최적화 → 기본 구현

## 📈 성공 지표

### 정량적 지표
- **테스트 커버리지**: 80% 이상
- **API 응답 시간**: 평균 200ms 미만
- **테스트 실행 시간**: 전체 30초 미만
- **에러율**: 1% 미만

### 정성적 지표
- **코드 리뷰**: 모든 PR에 대한 리뷰 완료
- **문서화**: API 스펙 문서 완성
- **운영 준비**: Docker 컨테이너 정상 실행
- **보안**: 인증/인가 로직 검증 완료

## 📅 일정표

### Week 1 (Day 1-5)
- **Day 1-2**: User Service 개발
  - Day 1 오전: 프로젝트 초기화
  - Day 1 오후 ~ Day 2: User/Session 모델 TDD
- **Day 3-4**: AuthController 개발
  - Day 3: 회원가입/로그인 API
  - Day 4: 로그아웃/검증 API, 미들웨어
- **Day 5**: User Service 마무리 및 테스트

### Week 2 (Day 6-10)  
- **Day 6-7**: Task Service 개발
  - Day 6 오전: 프로젝트 초기화
  - Day 6 오후 ~ Day 7: Task 모델, AuthService TDD
- **Day 8-9**: TasksController 개발
  - Day 8: CRUD API 구현
  - Day 9: 인증 연동, 필터링 기능
- **Day 10**: 통합 테스트 및 마무리

### 일일 체크포인트
- **매일 09:00**: 일일 계획 수립 및 이전 날 회고
- **매일 18:00**: 진행 상황 점검 및 다음 날 준비
- **매주 금요일**: 주간 회고 및 다음 주 계획

이 실행 계획을 따라 진행하면 체계적이고 안정적인 마이크로서비스를 구축할 수 있습니다.