class TaskServiceClient < BaseServiceClient
  def initialize
    super
    @base_url = ENV.fetch("TASK_SERVICE_URL", "http://localhost:3001")
  end

  def base_url
    @base_url
  end

  # Get user tasks for analytics calculation
  def get_user_tasks(user_id, session_token: nil)
    headers = { "X-User-ID" => user_id.to_s }
    headers["Authorization"] = "Bearer #{session_token}" if session_token

    make_request(:get, "#{@base_url}/api/v1/tasks?user_id=#{user_id}", {
      headers: headers
    })
  end

  # Get task statistics from Task Service
  def get_task_statistics(user_id, session_token: nil)
    headers = { "X-User-ID" => user_id.to_s }
    headers["Authorization"] = "Bearer #{session_token}" if session_token

    make_request(:get, "#{@base_url}/api/v1/tasks/statistics?user_id=#{user_id}", {
      headers: headers
    })
  end

  # Get tasks by status
  def get_tasks_by_status(user_id, status, session_token: nil)
    headers = { "X-User-ID" => user_id.to_s }
    headers["Authorization"] = "Bearer #{session_token}" if session_token

    make_request(:get, "#{@base_url}/api/v1/tasks?user_id=#{user_id}&status=#{status}", {
      headers: headers
    })
  end

  # Get tasks by priority
  def get_tasks_by_priority(user_id, priority, session_token: nil)
    headers = { "X-User-ID" => user_id.to_s }
    headers["Authorization"] = "Bearer #{session_token}" if session_token

    make_request(:get, "#{@base_url}/api/v1/tasks?user_id=#{user_id}&priority=#{priority}", {
      headers: headers
    })
  end

  # Get overdue tasks
  def get_overdue_tasks(user_id, session_token: nil)
    headers = { "X-User-ID" => user_id.to_s }
    headers["Authorization"] = "Bearer #{session_token}" if session_token

    make_request(:get, "#{@base_url}/api/v1/tasks/overdue?user_id=#{user_id}", {
      headers: headers
    })
  end

  # Get completed tasks for trend analysis
  def get_completed_tasks_in_range(user_id, start_date, end_date, session_token: nil)
    headers = { "X-User-ID" => user_id.to_s }
    headers["Authorization"] = "Bearer #{session_token}" if session_token

    query_params = build_query_params({
      user_id: user_id,
      status: "completed",
      start_date: start_date,
      end_date: end_date
    })

    make_request(:get, "#{@base_url}/api/v1/tasks?#{query_params}", {
      headers: headers
    })
  end
end
