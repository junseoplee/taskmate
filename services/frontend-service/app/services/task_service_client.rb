class TaskServiceClient < BaseServiceClient
  def initialize
    super
    @base_url = ENV.fetch("TASK_SERVICE_URL", "http://localhost:3001")
  end

  # Get user tasks with filtering
  def get_user_tasks(user_id, options = {})
    session_token = options.delete(:session_token)
    query_params = build_query_params(options.merge(user_id: user_id))
    url = "#{@base_url}/api/v1/tasks"
    url += "?#{query_params}" unless query_params.empty?

    headers = { "X-User-ID" => user_id.to_s }
    headers["Authorization"] = "Bearer #{session_token}" if session_token

    make_request(:get, url, { headers: headers })
  end

  # Get single task
  def get_task(task_id, options = {})
    session_token = options[:session_token]
    headers = {}
    headers["Authorization"] = "Bearer #{session_token}" if session_token

    make_request(:get, "#{@base_url}/api/v1/tasks/#{task_id}", { headers: headers })
  end

  # Create task
  def create_task(user_id, task_params, options = {})
    session_token = options[:session_token]
    headers = { "X-User-ID" => user_id.to_s }
    headers["Authorization"] = "Bearer #{session_token}" if session_token

    make_request(:post, "#{@base_url}/api/v1/tasks", {
      body: {
        task: task_params.merge(user_id: user_id)
      },
      headers: headers
    })
  end

  # Update task
  def update_task(task_id, task_params, options = {})
    session_token = options[:session_token]
    headers = {}
    headers["Authorization"] = "Bearer #{session_token}" if session_token

    make_request(:put, "#{@base_url}/api/v1/tasks/#{task_id}", {
      body: { task: task_params },
      headers: headers
    })
  end

  # Update task status
  def update_task_status(task_id, status, options = {})
    session_token = options[:session_token]
    headers = {}
    headers["Authorization"] = "Bearer #{session_token}" if session_token

    make_request(:patch, "#{@base_url}/api/v1/tasks/#{task_id}/status", {
      body: { status: status },
      headers: headers
    })
  end

  # Complete task
  def complete_task(task_id, options = {})
    session_token = options[:session_token]
    headers = {}
    headers["Authorization"] = "Bearer #{session_token}" if session_token

    make_request(:patch, "#{@base_url}/api/v1/tasks/#{task_id}/complete", {
      headers: headers
    })
  end

  # Delete task
  def delete_task(task_id, options = {})
    session_token = options[:session_token]
    headers = {}
    headers["Authorization"] = "Bearer #{session_token}" if session_token

    make_request(:delete, "#{@base_url}/api/v1/tasks/#{task_id}", {
      headers: headers
    })
  end

  # Search tasks
  def search_tasks(user_id, query, options = {})
    search_params = options.merge(q: query, user_id: user_id)
    query_params = build_query_params(search_params)

    make_request(:get, "#{@base_url}/api/v1/tasks/search?#{query_params}", {
      headers: {
        "X-User-ID" => user_id.to_s
      }
    })
  end

  # Get project tasks
  def get_project_tasks(project_id, user_id, options = {})
    query_params = build_query_params(options.merge(user_id: user_id))
    url = "#{@base_url}/api/v1/projects/#{project_id}/tasks"
    url += "?#{query_params}" unless query_params.empty?

    make_request(:get, url, {
      headers: {
        "X-User-ID" => user_id.to_s
      }
    })
  end

  # Bulk update tasks
  def bulk_update_tasks(task_ids, update_params)
    make_request(:patch, "#{@base_url}/api/v1/tasks/bulk_update", {
      body: {
        task_ids: task_ids,
        updates: update_params
      }
    })
  end

  # Get task statistics
  def get_task_statistics(user_id, date_range = nil)
    params = { user_id: user_id }
    params[:date_range] = date_range if date_range
    query_params = build_query_params(params)

    make_request(:get, "#{@base_url}/api/v1/tasks/statistics?#{query_params}", {
      headers: {
        "X-User-ID" => user_id.to_s
      }
    })
  end

  # Get task by status
  def get_tasks_by_status(user_id, status, options = {})
    get_user_tasks(user_id, options.merge(status: status))
  end

  # Get task by priority
  def get_tasks_by_priority(user_id, priority, options = {})
    get_user_tasks(user_id, options.merge(priority: priority))
  end

  # Get overdue tasks
  def get_overdue_tasks(user_id, options = {})
    make_request(:get, "#{@base_url}/api/v1/tasks/overdue?#{build_query_params(options.merge(user_id: user_id))}", {
      headers: {
        "X-User-ID" => user_id.to_s
      }
    })
  end

  # Get upcoming tasks
  def get_upcoming_tasks(user_id, days = 7, options = {})
    params = options.merge(user_id: user_id, days: days)
    make_request(:get, "#{@base_url}/api/v1/tasks/upcoming?#{build_query_params(params)}", {
      headers: {
        "X-User-ID" => user_id.to_s
      }
    })
  end

  private

  # Helper method to build headers with authentication
  def build_auth_headers(user_id = nil, session_token = nil)
    headers = {}
    headers["X-User-ID"] = user_id.to_s if user_id
    headers["Authorization"] = "Bearer #{session_token}" if session_token
    headers
  end
end
