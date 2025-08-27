class DashboardController < ApplicationController
  def index
    dashboard_data = fetch_dashboard_data
    @dashboard_data = dashboard_data[:analytics] || default_analytics
    @recent_tasks = dashboard_data[:recent_tasks] || []
    @error_message = dashboard_data[:error]

    Rails.logger.info "Dashboard data loaded: #{@dashboard_data.inspect}"
    Rails.logger.info "Recent tasks count: #{@recent_tasks.length}"

    respond_to do |format|
      format.html # Render HTML template
      format.json {
        render json: {
          analytics: @dashboard_data,
          recent_tasks: @recent_tasks,
          error: @error_message
        }
      }
    end
  end

  private

  def fetch_dashboard_data
    Rails.logger.info "=== Starting dashboard data fetch for user #{current_user['id']} ==="

    task_client = TaskServiceClient.new
    analytics_client = AnalyticsServiceClient.new

    begin
      # Recent tasks (5 tasks)
      Rails.logger.info "Fetching recent tasks..."
      tasks_response = task_client.get_user_tasks(current_user["id"], limit: 5, session_token: current_session_token)
      Rails.logger.info "Tasks response: #{tasks_response.inspect}"

      # Handle both Task Service response formats
      recent_tasks = if tasks_response["success"]
                      tasks_response["tasks"]
      elsif tasks_response["tasks"]
                      tasks_response["tasks"].first(5)
      else
                      []
      end
      Rails.logger.info "Processed recent_tasks: #{recent_tasks.length} tasks"

      # Analytics data
      Rails.logger.info "Fetching analytics data..."
      analytics_response = analytics_client.get_dashboard_summary(current_user["id"], session_token: current_session_token)
      Rails.logger.info "Analytics response: #{analytics_response.inspect}"

      # Handle Analytics Service response format
      analytics = if analytics_response["status"] == "success"
                   analytics_response["data"]
      elsif analytics_response["success"]
                   analytics_response["data"]
      else
                   Rails.logger.warn "Using default analytics data"
                   default_analytics
      end
      Rails.logger.info "Processed analytics: #{analytics.inspect}"

      result = {
        recent_tasks: recent_tasks,
        analytics: analytics,
        user: current_user
      }
      Rails.logger.info "=== Dashboard data fetch completed successfully ==="
      result

    rescue => e
      Rails.logger.error "Dashboard data fetch error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      {
        recent_tasks: [],
        analytics: default_analytics,
        user: current_user,
        error: "Failed to load dashboard data."
      }
    end
  end

  def default_analytics
    {
      total_tasks: 0,
      completed_tasks: 0,
      pending_tasks: 0,
      completion_rate: 0.0
    }
  end
end
