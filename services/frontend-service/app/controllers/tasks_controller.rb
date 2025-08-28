class TasksController < ApplicationController
  def index
    Rails.logger.info "=== Task Index Debug ==="
    Rails.logger.info "Session[:session_token]: #{session[:session_token] || 'NONE'}"
    Rails.logger.info "Current user: #{current_user.inspect}"

    # Check if this is a search request
    @search_query = params[:q] || ""

    if @search_query.present?
      # If search query is present, use search functionality
      task_client = TaskServiceClient.new
      @search_results = task_client.search_tasks(
        current_user["id"],
        @search_query,
        filter_params.merge(session_token: session[:session_token])
      )

      @tasks_data = {
        tasks: @search_results["tasks"] || [],
        pagination: {},
        filters: filter_params,
        total: @search_results["total"] || 0,
        search_query: @search_query
      }
    else
      # Regular fetch for all tasks
      @tasks_data = fetch_tasks_data
    end

    Rails.logger.info "Tasks data result: #{@tasks_data.inspect}"
    Rails.logger.info "Tasks count: #{@tasks_data[:tasks]&.count || 0}"
    Rails.logger.info "Error: #{@tasks_data[:error]}" if @tasks_data[:error]
  end

  def show
    @task = fetch_task(params[:id])
    redirect_to tasks_path, alert: "Task not found." unless @task
  end

  def new
    # New task form rendered via AJAX
  end

  def edit
    @task = fetch_task(params[:id])
    redirect_to tasks_path, alert: "Task not found." unless @task
  end

  def create
    task_client = TaskServiceClient.new

    # 디버깅을 위한 로그 추가
    Rails.logger.info "=== Task Creation Debug ==="
    Rails.logger.info "Full session: #{session.inspect}"
    Rails.logger.info "Session[:session_token]: #{session[:session_token] || 'NONE'}"
    Rails.logger.info "Session ID: #{session.id}"
    Rails.logger.info "Current user: #{current_user.inspect}"
    Rails.logger.info "Task params: #{task_params.inspect}"

    # API에 맞는 형식으로 파라미터 구성
    task_data = {
      title: task_params[:title],
      description: task_params[:description],
      status: task_params[:status] || "pending",
      priority: task_params[:priority] || "medium",
      due_date: task_params[:due_date],
      tags: task_params[:tags]
    }

    Rails.logger.info "Task data to send: #{task_data.inspect}"

    result = task_client.create_task(current_user["id"], task_data, session_token: session[:session_token])

    Rails.logger.info "Task creation result: #{result.inspect}"

    if result.is_a?(Hash) && (result["success"] || result["task"])
      redirect_to tasks_path, notice: "Task created successfully!"
    elsif result.respond_to?(:success?) && result.success?
      redirect_to tasks_path, notice: "Task created successfully!"
    else
      error_message = if result.is_a?(Hash)
        result["message"] || result["error"] || "Failed to create task."
      elsif result.respond_to?(:parsed_response)
        result.parsed_response["message"] || result.parsed_response["error"] || "Failed to create task."
      else
        "Failed to create task."
      end

      Rails.logger.error "Task creation failed with message: #{error_message}"
      flash.now[:alert] = error_message
      render :new, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "Task creation error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    flash.now[:alert] = "Failed to create task. Please try again."
    render :new, status: :unprocessable_entity
  end

  def update
    task_client = TaskServiceClient.new

    # If only status is being updated, use the status-specific endpoint
    if task_params.keys == [ "status" ]
      result = task_client.update_task_status(params[:id], task_params["status"], session_token: session[:session_token])

      # Task Service returns { task: ... } on success, { error: ... } or { errors: ... } on failure
      if result["task"]
        redirect_to tasks_path, notice: "Task status updated successfully!"
      else
        error_message = result["error"] || result["errors"]&.join(", ") || result["message"] || "Failed to update task status."
        redirect_to tasks_path, alert: error_message
      end
    else
      # For full task updates (from edit form)
      result = task_client.update_task(params[:id], task_params, session_token: session[:session_token])

      if result["success"]
        redirect_to task_path(params[:id]), notice: "Task updated successfully!"
      else
        flash.now[:alert] = result["message"] || "Failed to update task."
        @task = fetch_task(params[:id])
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def patch
    task_client = TaskServiceClient.new

    # Handle status completion
    if params[:status] == "completed"
      result = task_client.complete_task(params[:id], session_token: session[:session_token])
    else
      result = task_client.update_task(params[:id], { status: params[:status] }, session_token: session[:session_token])
    end

    if result["success"]
      redirect_to tasks_path, notice: "Task status updated successfully!"
    else
      redirect_to tasks_path, alert: result["message"] || "Failed to update task status."
    end
  end

  def destroy
    task_client = TaskServiceClient.new
    result = task_client.delete_task(params[:id], session_token: session[:session_token])

    if result["success"]
      redirect_to tasks_path, notice: "Task deleted successfully!"
    else
      redirect_to tasks_path, alert: result["message"] || "Failed to delete task."
    end
  end

  def search
    @search_query = params[:q] || ""

    if @search_query.present?
      task_client = TaskServiceClient.new
      @search_results = task_client.search_tasks(
        current_user["id"],
        @search_query,
        filter_params.merge(session_token: session[:session_token])
      )

      @tasks = @search_results["tasks"] || []
      @total = @search_results["total"] || 0
      @filters_applied = @search_results["filters_applied"] || {}
    else
      @tasks = []
      @total = 0
      @filters_applied = {}
    end
  end

  def statistics
    task_client = TaskServiceClient.new
    @stats_data = task_client.get_task_statistics(current_user["id"])
    @statistics = @stats_data["statistics"] || {}
  rescue => e
    Rails.logger.error "Statistics fetch error: #{e.message}"
    @statistics = {}
    flash.now[:alert] = "Unable to load statistics."
  end

  def overdue
    task_client = TaskServiceClient.new
    @overdue_data = task_client.get_overdue_tasks(
      current_user["id"],
      session_token: session[:session_token]
    )

    @tasks = @overdue_data["tasks"] || []
    @total = @overdue_data["total"] || 0
    @current_date = @overdue_data["current_date"]
  rescue => e
    Rails.logger.error "Overdue tasks fetch error: #{e.message}"
    @tasks = []
    flash.now[:alert] = "Unable to load overdue tasks."
  end

  def upcoming
    days = params[:days]&.to_i || 7
    task_client = TaskServiceClient.new

    @upcoming_data = task_client.get_upcoming_tasks(
      current_user["id"],
      days,
      session_token: session[:session_token]
    )

    @tasks = @upcoming_data["tasks"] || []
    @total = @upcoming_data["total"] || 0
    @date_range = @upcoming_data["date_range"] || {}
  rescue => e
    Rails.logger.error "Upcoming tasks fetch error: #{e.message}"
    @tasks = []
    flash.now[:alert] = "Unable to load upcoming tasks."
  end

  def bulk_update
    task_ids = params[:task_ids] || []
    updates = params[:updates] || {}

    if task_ids.empty? || updates.empty?
      return redirect_to tasks_path, alert: "Please select tasks and updates to apply."
    end

    task_client = TaskServiceClient.new
    result = task_client.bulk_update_tasks(task_ids, updates)

    if result["success_count"] && result["success_count"] > 0
      message = "Successfully updated #{result['success_count']} task(s)."
      message += " #{result['failure_count']} failed." if result["failure_count"] > 0
      redirect_to tasks_path, notice: message
    else
      redirect_to tasks_path, alert: "Failed to update tasks."
    end
  rescue => e
    Rails.logger.error "Bulk update error: #{e.message}"
    redirect_to tasks_path, alert: "Failed to update tasks."
  end

  def complete
    task_client = TaskServiceClient.new
    result = task_client.complete_task(params[:id], session_token: session[:session_token])

    if result["task"] && result["task"]["status"] == "completed"
      redirect_to tasks_path, notice: "Task marked as completed!"
    else
      redirect_to tasks_path, alert: result["message"] || "Failed to complete task."
    end
  rescue => e
    Rails.logger.error "Task completion error: #{e.message}"
    redirect_to tasks_path, alert: "Failed to complete task."
  end

  private

  def fetch_tasks_data
    task_client = TaskServiceClient.new

    begin
      # Fetch current user's tasks with session token for authentication
      options = filter_params.merge(session_token: session[:session_token])
      Rails.logger.info "=== Fetch Tasks Debug ==="
      Rails.logger.info "User ID: #{current_user['id']}"
      Rails.logger.info "Options: #{options.inspect}"

      response = task_client.get_user_tasks(current_user["id"], options)
      Rails.logger.info "Task service response: #{response.inspect}"

      # Task Service returns tasks array directly or success format
      if response["success"] || response["tasks"]
        tasks = response["tasks"] || response  # Support both response formats
        Rails.logger.info "Success! Tasks found: #{tasks&.count || 0}"
        {
          tasks: tasks,
          pagination: response["pagination"] || {},
          filters: filter_params
        }
      else
        Rails.logger.error "Task fetch failed: #{response['message']}"
        {
          tasks: [],
          pagination: {},
          filters: filter_params,
          error: response["message"]
        }
      end
    rescue => e
      Rails.logger.error "Task data fetch error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      {
        tasks: [],
        pagination: {},
        filters: filter_params,
        error: "Unable to load task data."
      }
    end
  end

  def fetch_task(task_id)
    task_client = TaskServiceClient.new
    response = task_client.get_task(task_id, session_token: session[:session_token])
    response["success"] ? response["task"] : nil
  rescue => e
    Rails.logger.error "Task fetch error: #{e.message}"
    nil
  end

  def task_params
    if params[:task]
      params.require(:task).permit(:title, :description, :status, :priority, :due_date, :tags)
    else
      params.permit(:title, :description, :status, :priority, :due_date, :tags)
    end
  end

  def filter_params
    params.permit(:status, :priority, :page, :per_page, :search).to_h.with_defaults(
      page: 1,
      per_page: 20
    )
  end
end
