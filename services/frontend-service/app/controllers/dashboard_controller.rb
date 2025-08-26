class DashboardController < ApplicationController
  def index
    @dashboard_data = fetch_dashboard_data
  end

  private

  def fetch_dashboard_data
    # Mock data for dashboard
    task_client = TaskServiceClient.new
    analytics_client = AnalyticsServiceClient.new
    
    begin
      # Recent tasks (5 tasks)
      tasks_response = task_client.get_user_tasks(current_user['id'], limit: 5)
      recent_tasks = tasks_response['success'] ? tasks_response['tasks'] : []
      
      # Analytics data
      analytics_response = analytics_client.get_dashboard_summary(current_user['id'])
      analytics = analytics_response['success'] ? analytics_response['data'] : default_analytics
      
      {
        recent_tasks: recent_tasks,
        analytics: analytics,
        user: current_user
      }
    rescue => e
      Rails.logger.error "Dashboard data fetch error: #{e.message}"
      {
        recent_tasks: [],
        analytics: default_analytics,
        user: current_user,
        error: 'Failed to load dashboard data.'
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