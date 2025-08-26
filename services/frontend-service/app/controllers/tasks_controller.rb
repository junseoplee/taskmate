class TasksController < ApplicationController
  def index
    @tasks_data = fetch_tasks_data
  end

  def show
    @task = fetch_task(params[:id])
    redirect_to tasks_path, alert: 'Task not found.' unless @task
  end

  def new
    # New task form rendered via AJAX
  end

  def edit
    @task = fetch_task(params[:id])
    redirect_to tasks_path, alert: 'Task not found.' unless @task
  end

  def create
    task_client = TaskServiceClient.new
    
    # API에 맞는 형식으로 파라미터 구성
    task_data = {
      title: task_params[:title],
      description: task_params[:description],
      status: task_params[:status] || 'pending',
      priority: task_params[:priority] || 'medium',
      due_date: task_params[:due_date],
      tags: task_params[:tags]
    }
    
    result = task_client.create_task(current_user['id'], task_data, session_token: session[:session_token])
    
    if result.is_a?(Hash) && result['success']
      redirect_to tasks_path, notice: 'Task created successfully!'
    elsif result.respond_to?(:success?) && result.success?
      redirect_to tasks_path, notice: 'Task created successfully!'
    else
      error_message = if result.is_a?(Hash)
        result['message'] || result['error'] || 'Failed to create task.'
      elsif result.respond_to?(:parsed_response)
        result.parsed_response['message'] || result.parsed_response['error'] || 'Failed to create task.'
      else
        'Failed to create task.'
      end
      
      flash.now[:alert] = error_message
      render :new, status: :unprocessable_entity
    end
  rescue => e
    Rails.logger.error "Task creation error: #{e.message}"
    flash.now[:alert] = 'Failed to create task. Please try again.'
    render :new, status: :unprocessable_entity
  end

  def update
    task_client = TaskServiceClient.new
    result = task_client.update_task(params[:id], task_params)
    
    if result['success']
      redirect_to task_path(params[:id]), notice: 'Task updated successfully!'
    else
      flash.now[:alert] = result['message'] || 'Failed to update task.'
      @task = fetch_task(params[:id])
      render :edit, status: :unprocessable_entity
    end
  end

  def patch
    task_client = TaskServiceClient.new
    
    # Handle status completion
    if params[:status] == 'completed'
      result = task_client.complete_task(params[:id])
    else
      result = task_client.update_task(params[:id], { status: params[:status] })
    end
    
    if result['success']
      redirect_to tasks_path, notice: 'Task status updated successfully!'
    else
      redirect_to tasks_path, alert: result['message'] || 'Failed to update task status.'
    end
  end

  def destroy
    task_client = TaskServiceClient.new
    result = task_client.delete_task(params[:id])
    
    if result['success']
      redirect_to tasks_path, notice: 'Task deleted successfully!'
    else
      redirect_to tasks_path, alert: result['message'] || 'Failed to delete task.'
    end
  end

  private

  def fetch_tasks_data
    task_client = TaskServiceClient.new
    
    begin
      # Fetch current user's tasks with session token for authentication
      options = filter_params.merge(session_token: session[:session_token])
      response = task_client.get_user_tasks(current_user['id'], options)
      
      if response['success']
        {
          tasks: response['tasks'] || [],
          pagination: response['pagination'] || {},
          filters: filter_params
        }
      else
        {
          tasks: [],
          pagination: {},
          filters: filter_params,
          error: response['message']
        }
      end
    rescue => e
      Rails.logger.error "Task data fetch error: #{e.message}"
      {
        tasks: [],
        pagination: {},
        filters: filter_params,
        error: 'Unable to load task data.'
      }
    end
  end

  def fetch_task(task_id)
    task_client = TaskServiceClient.new
    response = task_client.get_task(task_id, session_token: session[:session_token])
    response['success'] ? response['task'] : nil
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