class TasksController < ApplicationController
  def index
    Rails.logger.info "=== Task Index Debug ==="
    Rails.logger.info "Session[:session_token]: #{session[:session_token] || 'NONE'}"
    Rails.logger.info "Current user: #{current_user.inspect}"

    @tasks_data = fetch_tasks_data

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
    result = task_client.update_task(params[:id], task_params, session_token: session[:session_token])

    if result["success"]
      redirect_to task_path(params[:id]), notice: "Task updated successfully!"
    else
      flash.now[:alert] = result["message"] || "Failed to update task."
      @task = fetch_task(params[:id])
      render :edit, status: :unprocessable_entity
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
    params.permit(:title, :description, :status, :priority, :due_date, :tags)
  end

  def filter_params
    params.permit(:status, :priority, :page, :per_page, :search).to_h.with_defaults(
      page: 1,
      per_page: 20
    )
  end
end
