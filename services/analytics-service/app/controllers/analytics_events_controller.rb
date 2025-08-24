# frozen_string_literal: true

class AnalyticsEventsController < ApplicationController
  before_action :set_analytics_event, only: [ :show ]

  # GET /analytics_events
  def index
    @analytics_events = AnalyticsEvent.all

    # Apply filters
    @analytics_events = @analytics_events.by_type(params[:event_type]) if params[:event_type].present?
    @analytics_events = @analytics_events.by_service(params[:source_service]) if params[:source_service].present?

    if params[:start_date].present? && params[:end_date].present?
      @analytics_events = @analytics_events.by_date_range(params[:start_date], params[:end_date])
    end

    render json: @analytics_events
  end

  # GET /analytics_events/1
  def show
    render json: @analytics_event
  end

  # POST /analytics_events
  def create
    @analytics_event = AnalyticsEvent.new(analytics_event_params)

    if @analytics_event.save
      render json: @analytics_event, status: :created
    else
      render json: { errors: @analytics_event.errors }, status: :unprocessable_entity
    end
  end

  # GET /analytics_events/metrics
  def metrics
    total_events = AnalyticsEvent.count

    # Group by event type
    events_by_type = AnalyticsEvent.group(:event_type).count

    # Group by source service
    events_by_service = AnalyticsEvent.group(:source_service).count

    # Apply period filter if specified
    scope = AnalyticsEvent.all
    period = params[:period]

    case period
    when "today"
      scope = AnalyticsEvent.today
    when "this_week"
      scope = AnalyticsEvent.this_week
    when "this_month"
      scope = AnalyticsEvent.this_month
    end

    if period.present?
      total_events = scope.count
      events_by_type = scope.group(:event_type).count
      events_by_service = scope.group(:source_service).count
    end

    metrics = {
      total_events: total_events,
      events_by_type: events_by_type,
      events_by_service: events_by_service
    }

    metrics[:period] = period if period.present?

    render json: metrics
  end

  private

  def set_analytics_event
    @analytics_event = AnalyticsEvent.find(params[:id])
  end

  def analytics_event_params
    params.require(:analytics_event).permit(:event_name, :event_type, :source_service, :user_id, metadata: {})
  end
end
