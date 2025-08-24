class Api::V1::HealthController < ApplicationController
  def show
    # 데이터베이스 연결 확인
    db_status = check_database
    redis_status = check_redis

    overall_status = (db_status[:status] == "healthy" && redis_status[:status] == "healthy") ? "healthy" : "unhealthy"

    http_status = overall_status == "healthy" ? :ok : :service_unavailable

    render json: {
      service: "user-service",
      status: overall_status,
      timestamp: Time.current.iso8601,
      version: "1.0.0",
      dependencies: {
        database: db_status,
        redis: redis_status
      }
    }, status: http_status
  end

  private

  def check_database
    start_time = Time.current

    begin
      ActiveRecord::Base.connection.execute("SELECT 1")
      response_time = ((Time.current - start_time) * 1000).round

      {
        status: "healthy",
        response_time: response_time
      }
    rescue => e
      {
        status: "unhealthy",
        error: e.message
      }
    end
  end

  def check_redis
    start_time = Time.current

    begin
      # Redis 연결 확인 (세션 저장소로 사용)
      Rails.cache.fetch("health_check", expires_in: 1.second) { "ok" }
      response_time = ((Time.current - start_time) * 1000).round

      {
        status: "healthy",
        response_time: response_time
      }
    rescue => e
      {
        status: "unhealthy",
        error: e.message
      }
    end
  end
end
