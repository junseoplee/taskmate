class Api::V1::FileCategoriesController < ApplicationController
  before_action :set_file_category, only: [ :show, :update, :destroy, :file_types, :validate_file ]

  def index
    categories = FileCategory.all.order(:name)
    data = categories.map { |category| category_json(category) }
    render_success(data)
  end

  def show
    render_success(category_json(@file_category))
  end

  def create
    @file_category = FileCategory.new(file_category_params)

    if @file_category.save
      render_success(category_json(@file_category), status: :created)
    else
      render_error(@file_category.errors.as_json)
    end
  end

  def update
    if @file_category.update(file_category_params)
      render_success(category_json(@file_category))
    else
      render_error(@file_category.errors.as_json)
    end
  end

  def destroy
    @file_category.destroy
    head :no_content
  end

  def file_types
    data = {
      allowed_file_types: @file_category.allowed_file_types,
      max_file_size: @file_category.max_file_size,
      max_file_size_mb: @file_category.max_file_size ? (@file_category.max_file_size / 1.megabyte).round(1) : nil
    }
    render_success(data)
  end

  def validate_file
    file_params = params.require(:file).permit(:content_type, :file_size)
    content_type = file_params[:content_type]
    file_size = file_params[:file_size].to_i

    errors = []

    # 컨텐츠 타입 검증
    unless @file_category.allows_content_type?(content_type)
      errors << "파일 형식 '#{content_type}'은 이 카테고리에서 허용되지 않습니다"
    end

    # 파일 크기 검증
    unless @file_category.allows_file_size?(file_size)
      max_size_mb = (@file_category.max_file_size / 1.megabyte).round(1)
      errors << "파일 크기가 최대 허용 크기 #{max_size_mb}MB를 초과합니다"
    end

    data = {
      valid: errors.empty?,
      errors: errors
    }

    render_success(data)
  end

  private

  def set_file_category
    @file_category = FileCategory.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found('File category not found')
  end

  def file_category_params
    allowed_types = params[:file_category][:allowed_file_types]
    if allowed_types.is_a?(String)
      # JSON 문자열인 경우 파싱
      begin
        allowed_types = JSON.parse(allowed_types)
      rescue JSON::ParserError
        # 쉼표로 구분된 문자열인 경우
        allowed_types = allowed_types.split(',').map(&:strip)
      end
    end

    permitted_params = params.require(:file_category).permit(
      :name,
      :description,
      :max_file_size,
      allowed_file_types: []
    )

    permitted_params[:allowed_file_types] = allowed_types if allowed_types.present?
    permitted_params
  end

  def category_json(category)
    {
      id: category.id,
      name: category.name,
      description: category.description,
      allowed_file_types: category.allowed_file_types,
      max_file_size: category.max_file_size,
      max_file_size_mb: category.max_file_size ? (category.max_file_size / 1.megabyte).round(1) : nil,
      files_count: category.files_count,
      total_size: category.total_size,
      total_size_mb: category.total_size > 0 ? (category.total_size / 1.megabyte).round(2) : 0,
      created_at: category.created_at,
      updated_at: category.updated_at
    }
  end
end
