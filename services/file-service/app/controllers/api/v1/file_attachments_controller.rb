class Api::V1::FileAttachmentsController < ApplicationController
  before_action :set_file_attachment, only: [ :show, :update, :destroy, :upload_complete, :upload_failed ]

  def index
    attachments = FileAttachment.all

    # 필터링
    attachments = attachments.by_category(params[:category_id]) if params[:category_id].present?

    # file_type 또는 content_type 파라미터 처리
    content_type_param = params[:file_type] || params[:content_type]
    attachments = attachments.by_content_type(content_type_param) if content_type_param.present?

    # 검색 필터링 추가
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      attachments = attachments.where("original_filename ILIKE ?", search_term)
    end

    if params[:attachable_type].present? && params[:attachable_id].present?
      attachments = attachments.where(
        attachable_type: params[:attachable_type],
        attachable_id: params[:attachable_id]
      )
    end

    # 최신순 정렬
    attachments = attachments.order(created_at: :desc)

    # 페이지네이션 (기본 20개)
    page = params[:page]&.to_i || 1
    per_page = [ params[:per_page]&.to_i || 20, 100 ].min

    total_count = attachments.count
    attachments = attachments.limit(per_page).offset((page - 1) * per_page)

    data = attachments.map { |attachment| attachment_json(attachment) }

    render_success({
      items: data,
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil
      }
    })
  end

  def show
    render_success(attachment_json(@file_attachment))
  end

  def create
    @file_attachment = FileAttachment.new(file_attachment_params)

    if @file_attachment.save
      render_success(attachment_json(@file_attachment), status: :created)
    else
      render_error(@file_attachment.errors.as_json)
    end
  end

  def update
    if @file_attachment.update(file_attachment_params)
      render_success(attachment_json(@file_attachment))
    else
      render_error(@file_attachment.errors.as_json)
    end
  end

  def destroy
    @file_attachment.destroy
    head :no_content
  end

  def upload_complete
    @file_attachment.mark_as_completed!
    render_success(attachment_json(@file_attachment))
  end

  def upload_failed
    @file_attachment.mark_as_failed!
    render_success(attachment_json(@file_attachment))
  end

  def statistics
    user_id = params[:user_id]

    unless user_id.present?
      return render_error({ user_id: [ "User ID is required" ] }, status: :bad_request)
    end

    stats = FileAttachment.statistics_for_user(user_id)

    render_success({
      statistics: stats,
      generated_at: Time.current,
      user_id: user_id
    })
  end

  private

  def set_file_attachment
    @file_attachment = FileAttachment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found("File attachment not found")
  end

  def file_attachment_params
    params.require(:file_attachment).permit(
      :original_filename,
      :file_url,
      :content_type,
      :file_size,
      :attachable_type,
      :attachable_id,
      :file_category_id,
      :upload_status
    )
  end

  def attachment_json(attachment)
    {
      id: attachment.id,
      original_filename: attachment.original_filename,
      file_url: attachment.file_url,
      file_category_id: attachment.file_category_id,
      created_at: attachment.created_at,
      file_category: attachment.file_category ? {
        id: attachment.file_category.id,
        name: attachment.file_category.name
      } : nil
    }
  end
end
