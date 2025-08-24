class Api::V1::AnalyticsController < ApplicationController
  # GET /api/v1/analytics/dashboard
  def dashboard
    stats = calculate_dashboard_stats

    render json: {
      status: "success",
      data: {
        total_tasks: stats[:total_tasks],
        completed_tasks: stats[:completed_tasks],
        completion_rate: stats[:completion_rate],
        pending_tasks: stats[:pending_tasks],
        in_progress_tasks: stats[:in_progress_tasks],
        high_priority_tasks: stats[:high_priority_tasks],
        overdue_tasks: stats[:overdue_tasks],
        period: "all_time",
        generated_at: Time.current
      }
    }
  end

  # GET /api/v1/analytics/tasks/completion-rate
  def completion_rate
    rate = calculate_completion_rate

    render json: {
      status: "success",
      data: {
        completion_rate: rate[:rate],
        total_tasks: rate[:total],
        completed_tasks: rate[:completed],
        period: "all_time"
      }
    }
  end

  # GET /api/v1/analytics/completion-trend
  def completion_trend
    trend_data = calculate_completion_trend

    render json: {
      status: "success",
      data: {
        trend_data: trend_data,
        period: "30_days",
        generated_at: Time.current
      }
    }
  end

  # GET /api/v1/analytics/priority-distribution
  def priority_distribution
    distribution = calculate_priority_distribution

    render json: {
      status: "success",
      data: {
        distribution: distribution,
        total_tasks: distribution.values.sum,
        generated_at: Time.current
      }
    }
  end

  # POST /api/v1/analytics/events
  def create_event
    event_params = params.require(:event).permit(:event_type, :user_id, :task_id, :data)

    event = AnalyticsEvent.create!(
      event_name: "#{event_params[:event_type]}_event",
      event_type: event_params[:event_type] == "task" ? "task" : "user",
      source_service: "analytics-service",
      user_id: event_params[:user_id],
      metadata: {
        task_id: event_params[:task_id],
        data: event_params[:data] || {}
      },
      occurred_at: Time.current
    )

    render json: {
      status: "success",
      data: {
        event_id: event.id
      },
      message: "이벤트가 성공적으로 기록되었습니다."
    }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      status: "error",
      error: "validation_failed",
      message: "이벤트 생성 실패",
      details: e.record.errors.full_messages
    }, status: :unprocessable_entity
  end

  private

  def calculate_dashboard_stats
    # Task Service에서 데이터를 가져오는 대신 로컬 Analytics DB에서 집계
    # 실제 프로덕션에서는 Task Service API를 호출하거나 동기화된 데이터 사용

    # 예시 데이터 - 실제로는 Analytics DB에서 집계된 데이터 사용
    total_tasks = 150
    completed_tasks = 85
    pending_tasks = 45
    in_progress_tasks = 20
    high_priority_tasks = 25
    overdue_tasks = 8

    completion_rate = total_tasks > 0 ? (completed_tasks.to_f / total_tasks * 100).round(2) : 0

    {
      total_tasks: total_tasks,
      completed_tasks: completed_tasks,
      completion_rate: completion_rate,
      pending_tasks: pending_tasks,
      in_progress_tasks: in_progress_tasks,
      high_priority_tasks: high_priority_tasks,
      overdue_tasks: overdue_tasks
    }
  end

  def calculate_completion_rate
    # 완료율 계산 로직
    total = 150
    completed = 85
    rate = total > 0 ? (completed.to_f / total * 100).round(2) : 0

    {
      total: total,
      completed: completed,
      rate: rate
    }
  end

  def calculate_completion_trend
    # 지난 30일간의 완료 추세 데이터
    trend_data = []

    (0..29).each do |days_ago|
      date = Date.current - days_ago.days
      # 실제로는 Analytics DB에서 해당 날짜의 완료 태스크 수 조회
      completed_count = rand(0..8) # 예시 데이터

      trend_data.unshift({
        date: date.strftime("%Y-%m-%d"),
        completed_tasks: completed_count
      })
    end

    trend_data
  end

  def calculate_priority_distribution
    # 우선순위별 태스크 분포
    {
      "high" => 25,
      "medium" => 75,
      "low" => 50
    }
  end
end
