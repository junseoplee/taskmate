class Api::V1::AnalyticsController < ApplicationController
  before_action :authenticate_user!
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
    user_id = current_user["id"]
    session_token = extract_session_token
    task_client = TaskServiceClient.new

    # Get all user tasks
    all_tasks_response = task_client.get_user_tasks(user_id, session_token: session_token)

    if all_tasks_response && all_tasks_response["tasks"]
      tasks = all_tasks_response["tasks"] || []

      total_tasks = tasks.length
      completed_tasks = tasks.count { |task| task["status"] == "completed" }
      pending_tasks = tasks.count { |task| task["status"] == "pending" }
      in_progress_tasks = tasks.count { |task| task["status"] == "in_progress" }
      high_priority_tasks = tasks.count { |task| task["priority"] == "high" }

      # Calculate overdue tasks
      current_date = Date.current
      overdue_tasks = tasks.count do |task|
        task["due_date"] && Date.parse(task["due_date"]) < current_date && task["status"] != "completed"
      end

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
    else
      # Fallback data if Task Service is unavailable
      Rails.logger.error "Failed to fetch tasks from Task Service: #{all_tasks_response&.inspect}"
      {
        total_tasks: 0,
        completed_tasks: 0,
        completion_rate: 0,
        pending_tasks: 0,
        in_progress_tasks: 0,
        high_priority_tasks: 0,
        overdue_tasks: 0
      }
    end
  end

  def calculate_completion_rate
    user_id = current_user["id"]
    session_token = extract_session_token
    task_client = TaskServiceClient.new

    # Get all user tasks
    all_tasks_response = task_client.get_user_tasks(user_id, session_token: session_token)

    if all_tasks_response["success"]
      tasks = all_tasks_response["tasks"] || []

      total = tasks.length
      completed = tasks.count { |task| task["status"] == "completed" }
      rate = total > 0 ? (completed.to_f / total * 100).round(2) : 0

      {
        total: total,
        completed: completed,
        rate: rate
      }
    else
      Rails.logger.error "Failed to fetch tasks for completion rate: #{all_tasks_response['message']}"
      {
        total: 0,
        completed: 0,
        rate: 0
      }
    end
  end

  def calculate_completion_trend
    user_id = current_user["id"]
    session_token = extract_session_token
    task_client = TaskServiceClient.new

    trend_data = []
    start_date = 30.days.ago.to_date
    end_date = Date.current

    # Get completed tasks in date range
    completed_tasks_response = task_client.get_completed_tasks_in_range(
      user_id, start_date, end_date, session_token: session_token
    )

    if completed_tasks_response["success"]
      completed_tasks = completed_tasks_response["tasks"] || []

      # Group by completion date
      tasks_by_date = completed_tasks.group_by do |task|
        task["completed_at"] ? Date.parse(task["completed_at"]) : Date.current
      end

      (0..29).each do |days_ago|
        date = Date.current - days_ago.days
        completed_count = tasks_by_date[date]&.length || 0

        trend_data.unshift({
          date: date.strftime("%Y-%m-%d"),
          completed_tasks: completed_count
        })
      end
    else
      Rails.logger.error "Failed to fetch completion trend data: #{completed_tasks_response['message']}"
      # Fallback: empty trend data
      (0..29).each do |days_ago|
        date = Date.current - days_ago.days
        trend_data.unshift({
          date: date.strftime("%Y-%m-%d"),
          completed_tasks: 0
        })
      end
    end

    trend_data
  end

  def calculate_priority_distribution
    user_id = current_user["id"]
    session_token = extract_session_token
    task_client = TaskServiceClient.new

    # Get all user tasks
    all_tasks_response = task_client.get_user_tasks(user_id, session_token: session_token)

    if all_tasks_response["success"]
      tasks = all_tasks_response["tasks"] || []

      # Count tasks by priority
      distribution = {
        "high" => tasks.count { |task| task["priority"] == "high" },
        "medium" => tasks.count { |task| task["priority"] == "medium" },
        "low" => tasks.count { |task| task["priority"] == "low" }
      }
    else
      Rails.logger.error "Failed to fetch tasks for priority distribution: #{all_tasks_response['message']}"
      # Fallback: empty distribution
      {
        "high" => 0,
        "medium" => 0,
        "low" => 0
      }
    end
  end
end
