require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

# 선택적 gem 로딩
begin
  require 'database_cleaner/active_record'
rescue LoadError
  # database_cleaner가 없으면 transactional fixtures 사용
end

begin
  require 'webmock/rspec'
  WebMock.disable_net_connect!(allow_localhost: true)
rescue LoadError
  # webmock이 없으면 스킵
end

begin
  require 'vcr'
  VCR.configure do |config|
    config.cassette_library_dir = "spec/vcr_cassettes"
    config.hook_into :webmock
    config.configure_rspec_metadata!
    config.allow_http_connections_when_no_cassette = false
  end
rescue LoadError
  # vcr이 없으면 스킵
end

begin
  require 'timecop'
rescue LoadError
  # timecop이 없으면 스킵
end

# 테스트 커버리지 설정 (선택적)
begin
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
rescue LoadError
  # simplecov가 없으면 스킵
end

# Checks for pending migrations and applies them before tests are run.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

# RSpec 기본 설정
RSpec.configure do |config|
  # Database Cleaner가 있으면 사용, 없으면 transactional fixtures 사용
  if defined?(DatabaseCleaner)
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
  else
    config.use_transactional_fixtures = true
  end
  
  # Timecop 정리 (있으면)
  if defined?(Timecop)
    config.after(:each) do
      Timecop.return
    end
  end
  
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  
  # 공통 헬퍼 메서드
  config.include ActiveSupport::Testing::TimeHelpers
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

# FactoryBot 설정 (있으면)
if defined?(FactoryBot)
  RSpec.configure do |config|
    config.include FactoryBot::Syntax::Methods
  end
end

# Shoulda Matchers 설정 (있으면)
if defined?(Shoulda::Matchers)
  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end
end

# 헬퍼 모듈 include
RSpec.configure do |config|
  config.include JsonHelpers, type: :request
end
