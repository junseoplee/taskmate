class Api::V1::TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task, only: [ :show, :update, :destroy, :update_status, :complete ]

  # GET /api/v1/tasks
  def index
    tasks = current_user_tasks

    # Apply filters
    tasks = tasks.by_status(params[:status]) if params[:status].present?
    tasks = tasks.by_priority(params[:priority]) if params[:priority].present?

    # Date range filtering for completed tasks (for analytics trend data)
    if params[:start_date].present? && params[:end_date].present? && params[:status] == 'completed'
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      tasks = tasks.where(completed_at: start_date..end_date)
    end

    case params[:filter]
    when 'overdue'
      tasks = tasks.overdue
    when 'due_soon'
      tasks = tasks.due_soon
    end

    render json: {
      success: true,
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
      render json: { success: true, task: @task, message: "Task updated successfully" }
    else
      render json: { success: false, errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/tasks/:id
  def destroy
    if @task.destroy
      render json: { success: true, message: "Task deleted successfully" }
    else
      render json: { success: false, errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
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

  # PATCH /api/v1/tasks/:id/complete
  def complete
    begin
      @task.update_status!("completed")
      render json: {
        task: @task.reload,
        message: "Task marked as completed successfully"
      }
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/tasks/search
  def search
    tasks = current_user_tasks

    # Apply search query
    if params[:q].present?
      tasks = tasks.search_text(params[:q])
    end

    # Apply filters
    tasks = tasks.by_status(params[:status]) if params[:status].present?
    tasks = tasks.by_priority(params[:priority]) if params[:priority].present?

    # Apply date filters
    case params[:filter]
    when 'overdue'
      tasks = tasks.overdue
    when 'due_soon'
      tasks = tasks.due_soon
    end

    render json: {
      tasks: tasks.order(created_at: :desc),
      total: tasks.count,
      query: params[:q],
      filters_applied: {
        status: params[:status],
        priority: params[:priority],
        filter: params[:filter]
      }.compact
    }
  end

  # GET /api/v1/tasks/statistics
  def statistics
    stats = Task.statistics_for_user(@current_user_id)

    render json: {
      statistics: stats,
      generated_at: Time.current
    }
  end

  # GET /api/v1/tasks/overdue
  def overdue
    tasks = current_user_tasks.overdue.where.not(status: 'completed')

    render json: {
      tasks: tasks.order(:due_date),
      total: tasks.count,
      current_date: Date.current
    }
  end

  # GET /api/v1/tasks/upcoming
  def upcoming
    days = params[:days]&.to_i || 7
    end_date = days.days.from_now.to_date

    tasks = current_user_tasks
      .where("due_date BETWEEN ? AND ?", Date.current, end_date)
      .where.not(status: 'completed')

    render json: {
      tasks: tasks.order(:due_date),
      total: tasks.count,
      date_range: {
        from: Date.current,
        to: end_date,
        days: days
      }
    }
  end

  # PATCH /api/v1/tasks/bulk_update
  def bulk_update
    unless params[:task_ids].present? && params[:updates].present?
      return render json: {
        error: "task_ids and updates parameters are required"
      }, status: :bad_request
    end

    task_ids = params[:task_ids]
    updates = params[:updates].permit(:status, :priority, :due_date, :description)

    # Validate task ownership
    tasks = current_user_tasks.where(id: task_ids)

    if tasks.count != task_ids.length
      return render json: {
        error: "Some tasks not found or not owned by user"
      }, status: :not_found
    end

    # Perform bulk update
    success_count = 0
    failure_count = 0
    errors = []

    tasks.each do |task|
      begin
        if updates[:status].present? && updates[:status] != task.status
          task.update_status!(updates[:status])
        else
          task.update!(updates.except(:status))
        end
        success_count += 1
      rescue ActiveRecord::RecordInvalid => e
        failure_count += 1
        errors << {
          task_id: task.id,
          errors: e.record.errors.full_messages
        }
      end
    end

    render json: {
      success_count: success_count,
      failure_count: failure_count,
      total_requested: task_ids.length,
      errors: errors,
      updated_tasks: tasks.reload
    }
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
