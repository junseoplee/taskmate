class AnalyticsController < ApplicationController
  def index
    @analytics_data = fetch_analytics_data
  end

  def dashboard
    render json: fetch_dashboard_analytics
  end

  def completion_chart
    render json: fetch_completion_chart_data
  end

  def priority_distribution
    render json: fetch_priority_distribution_data
  end

  private

  def fetch_analytics_data
    analytics_client = AnalyticsServiceClient.new
    
    begin
      response = analytics_client.get_user_analytics(current_user['id'])
      
      if response['success']
        response['data'] || default_analytics_data
      else
        default_analytics_data.merge(error: response['message'])
      end
    rescue => e
      Rails.logger.error "Analytics data fetch error: #{e.message}"
      default_analytics_data.merge(error: 'Unable to load analytics data.')
    end
  end

  def fetch_dashboard_analytics
    analytics_client = AnalyticsServiceClient.new
    
    begin
      response = analytics_client.get_dashboard_summary(current_user['id'])
      
      if response['success']
        response['data'] || default_analytics_data
      else
        { error: response['message'] }
      end
    rescue => e
      Rails.logger.error "Dashboard analytics fetch error: #{e.message}"
      { error: 'Unable to load analytics data.' }
    end
  end

  def fetch_completion_chart_data
    analytics_client = AnalyticsServiceClient.new
    
    begin
      response = analytics_client.get_completion_trend(current_user['id'], period: params[:period] || '7d')
      
      if response['success']
        response['data'] || { trend_data: [] }
      else
        { error: response['message'] }
      end
    rescue => e
      Rails.logger.error "Completion chart data fetch error: #{e.message}"
      { error: 'Unable to load chart data.' }
    end
  end

  def fetch_priority_distribution_data
    analytics_client = AnalyticsServiceClient.new
    
    begin
      response = analytics_client.get_priority_distribution(current_user['id'])
      
      if response['success']
        response['data'] || default_priority_distribution
      else
        { error: response['message'] }
      end
    rescue => e
      Rails.logger.error "Priority distribution data fetch error: #{e.message}"
      { error: 'Unable to load priority data.' }
    end
  end

  def default_analytics_data
    {
      total_tasks: 0,
      completed_tasks: 0,
      pending_tasks: 0,
      in_progress_tasks: 0,
      completion_rate: 0.0,
      average_completion_time: 0,
      priority_distribution: default_priority_distribution,
      completion_trend: []
    }
  end

  def default_priority_distribution
    {
      urgent: 0,
      high: 0,
      medium: 0,
      low: 0
    }
  end
end