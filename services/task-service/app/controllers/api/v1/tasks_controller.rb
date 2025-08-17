class Api::V1::TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task, only: [:show, :update, :destroy, :update_status]
  
  # GET /api/v1/tasks
  def index
    tasks = current_user_tasks
    
    # Apply filters
    tasks = tasks.by_status(params[:status]) if params[:status].present?
    tasks = tasks.by_priority(params[:priority]) if params[:priority].present?
    
    case params[:filter]
    when 'overdue'
      tasks = tasks.overdue
    when 'due_soon'
      tasks = tasks.due_soon
    end
    
    render json: { 
      tasks: tasks.order(created_at: :desc),
      total: tasks.count
    }
  end
  
  # GET /api/v1/tasks/:id
  def show
    render json: { task: @task }
  end
  
  # POST /api/v1/tasks
  def create
    @task = current_user_tasks.build(task_params)
    
    if @task.save
      render json: { task: @task }, status: :created
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # PUT /api/v1/tasks/:id
  def update
    if @task.update(task_params)
      render json: { task: @task }
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/tasks/:id
  def destroy
    @task.destroy
    head :no_content
  end
  
  # PATCH /api/v1/tasks/:id/status
  def update_status
    unless params[:status].present?
      return render json: { error: "Status parameter is required" }, status: :bad_request
    end
    
    begin
      @task.update_status!(params[:status])
      render json: { task: @task.reload }
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  private
  
  def current_user_tasks
    Task.by_user(@current_user_id)
  end
  
  def set_task
    @task = current_user_tasks.find_by(id: params[:id])
    
    unless @task
      render json: { error: "Task not found" }, status: :not_found
    end
  end
  
  def task_params
    params.require(:task).permit(:title, :description, :priority, :due_date, :status)
      .tap { |p| p[:user_id] = @current_user_id }
  end
end