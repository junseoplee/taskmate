# frozen_string_literal: true

class AnalyticsSummariesController < ApplicationController
  before_action :set_analytics_summary, only: [:show]

  # GET /analytics_summaries
  def index
    @analytics_summaries = AnalyticsSummary.all
    
    # Apply filters
    @analytics_summaries = @analytics_summaries.by_metric(params[:metric_name]) if params[:metric_name].present?
    @analytics_summaries = @analytics_summaries.by_period(params[:time_period]) if params[:time_period].present?
    
    render json: @analytics_summaries
  end

  # GET /analytics_summaries/1
  def show
    render json: @analytics_summary
  end

  # POST /analytics_summaries
  def create
    @analytics_summary = AnalyticsSummary.new(analytics_summary_params)

    if @analytics_summary.save
      render json: @analytics_summary, status: :created
    else
      render json: { errors: @analytics_summary.errors }, status: :unprocessable_entity
    end
  end

  # GET /analytics_summaries/dashboard
  def dashboard
    # Get all summaries or filter by period
    scope = AnalyticsSummary.all
    period = params[:period]
    
    case period
    when 'daily'
      scope = AnalyticsSummary.by_period('daily')
    when 'weekly'
      scope = AnalyticsSummary.by_period('weekly')
    when 'monthly'
      scope = AnalyticsSummary.by_period('monthly')
    when 'today'
      scope = AnalyticsSummary.today
    when 'this_week'
      scope = AnalyticsSummary.this_week
    when 'this_month'
      scope = AnalyticsSummary.this_month
    end
    
    # Generate chart data
    chart_data = scope.map(&:to_chart_data)
    
    # Generate summary metrics
    summary_metrics = {
      total_count: scope.where(metric_type: 'count').sum(:metric_value),
      average_value: scope.where(metric_type: 'average').average(:metric_value)&.round(2) || 0,
      total_sum: scope.where(metric_type: 'sum').sum(:metric_value),
      percentage_metrics: scope.where(metric_type: 'percentage').count
    }
    
    dashboard_data = {
      chart_data: chart_data,
      summary_metrics: summary_metrics,
      total_summaries: scope.count
    }
    
    dashboard_data[:period] = period if period.present?
    
    render json: dashboard_data
  end

  # GET /analytics_summaries/chart_data
  def chart_data
    scope = AnalyticsSummary.all
    
    # Apply metric filter
    scope = scope.by_metric(params[:metric_name]) if params[:metric_name].present?
    
    chart_data = scope.map(&:to_chart_data)
    
    render json: chart_data
  end

  private

  def set_analytics_summary
    @analytics_summary = AnalyticsSummary.find(params[:id])
  end

  def analytics_summary_params
    params.require(:analytics_summary).permit(:metric_name, :metric_type, :metric_value, :time_period, :user_id, metadata: {})
  end
end