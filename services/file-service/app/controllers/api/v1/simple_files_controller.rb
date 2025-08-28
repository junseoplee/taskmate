class Api::V1::SimpleFilesController < ApplicationController
  before_action :set_simple_file, only: [ :show, :destroy ]

  def index
    files = SimpleFile.by_user(params[:user_id])

    # Filter by category
    files = files.by_category(params[:category_id]) if params[:category_id].present?

    # Filter by file type
    files = files.by_file_type(params[:file_type]) if params[:file_type].present?

    # Search by filename
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      files = files.where("filename ILIKE ?", search_term)
    end

    # Order by creation time (newest first)
    files = files.order(created_at: :desc)

    # Pagination
    page = params[:page]&.to_i || 1
    per_page = [ params[:per_page]&.to_i || 20, 100 ].min

    total_count = files.count
    files = files.limit(per_page).offset((page - 1) * per_page)

    data = files.map { |file| file_json(file) }

    render_success({
      files: data,
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil
      }
    })
  end

  def show
    render_success(file_json(@simple_file))
  end

  def create
    # Determine file type from filename
    file_type = SimpleFile.determine_file_type(file_params[:filename])

    @simple_file = SimpleFile.new(file_params.merge(file_type: file_type))

    if @simple_file.save
      render_success(file_json(@simple_file), status: :created)
    else
      render_error(@simple_file.errors.as_json, status: :unprocessable_entity)
    end
  end

  def destroy
    @simple_file.destroy
    head :no_content
  end

  def statistics
    user_id = params[:user_id]

    unless user_id.present?
      return render_error({ user_id: [ "User ID is required" ] }, status: :bad_request)
    end

    stats = SimpleFile.statistics_for_user(user_id)

    render_success({
      statistics: stats,
      generated_at: Time.current,
      user_id: user_id
    })
  end

  private

  def set_simple_file
    @simple_file = SimpleFile.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found("File not found")
  end

  def file_params
    params.require(:simple_file).permit(
      :filename,
      :file_url,
      :user_id,
      :file_category_id
    )
  end

  def file_json(file)
    {
      id: file.id,
      filename: file.filename,
      file_url: file.file_url,
      file_type: file.file_type,
      file_category_id: file.file_category_id,
      created_at: file.created_at,
      file_category: file.file_category ? {
        id: file.file_category.id,
        name: file.file_category.name
      } : nil
    }
  end
end
