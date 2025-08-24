require "redis"
require "net/http"

class Api::V1::HealthController < ApplicationController
  def show
    health_status = check_health

    render json: {
      service: "analytics-service",
      status: health_status[:overall_status],
      timestamp: Time.current,
      version: "1.0.0",
      dependencies: health_status[:dependencies]
    }
  end

  private

  def check_health
    dependencies = {}
    overall_status = "healthy"

    # Database 연결 확인
    begin
      start_time = Time.current
      ActiveRecord::Base.connection.execute("SELECT 1")
      dependencies[:database] = {
        status: "healthy",
        response_time: ((Time.current - start_time) * 1000).round
      }
    rescue => e
      dependencies[:database] = {
        status: "unhealthy",
        error: e.message
      }
      overall_status = "unhealthy"
    end

    # Redis 연결 확인
    begin
      start_time = Time.current
      redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://redis:6379/0"))
      redis.ping
      dependencies[:redis] = {
        status: "healthy",
        response_time: ((Time.current - start_time) * 1000).round
      }
      redis.close
    rescue => e
      dependencies[:redis] = {
        status: "unhealthy",
        error: e.message
      }
      overall_status = "unhealthy"
    end

    # User Service 연결 확인
    begin
      start_time = Time.current
      response = Net::HTTP.get_response(URI("http://user-service:3000/up"))
      dependencies[:user_service] = {
        status: response.code == "200" ? "healthy" : "unhealthy",
        response_time: ((Time.current - start_time) * 1000).round
      }
    rescue => e
      dependencies[:user_service] = {
        status: "unhealthy",
        error: e.message
      }
    end

    {
      overall_status: overall_status,
      dependencies: dependencies
    }
  end
end
