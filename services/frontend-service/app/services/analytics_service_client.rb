class AnalyticsServiceClient < BaseServiceClient
  private

  def base_url
    ENV.fetch('ANALYTICS_SERVICE_URL', 'http://localhost:3002')
  end

  public

  def get_dashboard_summary(user_id)
    get("/api/v1/analytics/dashboard", headers: auth_headers, query: { user_id: user_id })
  rescue => e
    handle_error(e, "Failed to fetch dashboard summary")
  end

  def get_user_analytics(user_id, date_range = nil)
    query_params = { user_id: user_id }
    query_params[:date_range] = date_range if date_range
    
    get("/api/v1/analytics/user", headers: auth_headers, query: query_params)
  rescue => e
    handle_error(e, "Failed to fetch user analytics")
  end

  def track_event(user_id, event_type, metadata = {})
    post("/api/v1/analytics/events", {
      headers: auth_headers,
      body: {
        user_id: user_id,
        event_type: event_type,
        metadata: metadata
      }.to_json
    })
  rescue => e
    handle_error(e, "Failed to track event")
  end
end