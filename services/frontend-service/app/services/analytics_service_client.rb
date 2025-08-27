class AnalyticsServiceClient < BaseServiceClient
  def base_url
    ENV.fetch("ANALYTICS_SERVICE_URL", "http://localhost:3002")
  end

  def get_dashboard_summary(user_id, session_token: nil)
    headers = auth_headers(session_token: session_token)
    headers["X-User-ID"] = user_id.to_s

    get("/api/v1/analytics/dashboard", headers: headers)
  rescue => e
    handle_error(e, "Failed to fetch dashboard summary")
  end

  def get_user_analytics(user_id, date_range = nil, session_token: nil)
    headers = auth_headers(session_token: session_token)
    headers["X-User-ID"] = user_id.to_s

    query_params = date_range ? { date_range: date_range } : {}

    get("/api/v1/analytics/user", headers: headers, query: query_params)
  rescue => e
    handle_error(e, "Failed to fetch user analytics")
  end

  def get_completion_trend(user_id, period: "30d", session_token: nil)
    headers = auth_headers(session_token: session_token)
    headers["X-User-ID"] = user_id.to_s

    get("/api/v1/analytics/completion-trend", headers: headers, query: { period: period })
  rescue => e
    handle_error(e, "Failed to fetch completion trend")
  end

  def get_priority_distribution(user_id, session_token: nil)
    headers = auth_headers(session_token: session_token)
    headers["X-User-ID"] = user_id.to_s

    get("/api/v1/analytics/priority-distribution", headers: headers)
  rescue => e
    handle_error(e, "Failed to fetch priority distribution")
  end

  def track_event(user_id, event_type, metadata = {}, session_token: nil)
    headers = auth_headers(session_token: session_token)
    headers["X-User-ID"] = user_id.to_s

    post("/api/v1/analytics/events", {
      headers: headers,
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
