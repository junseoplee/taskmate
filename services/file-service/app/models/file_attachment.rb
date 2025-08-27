class FileAttachment < ApplicationRecord
  belongs_to :attachable, polymorphic: true, optional: true
  belongs_to :file_category, optional: true

  validates :original_filename, presence: true, length: { maximum: 255 }
  validates :file_url, presence: true, length: { maximum: 500 }
  validates :content_type, presence: true, length: { maximum: 100 }
  validates :file_size, presence: true, numericality: { greater_than: 0 }
  validates :attachable_type, presence: true
  validates :attachable_id, presence: true

  validate :file_url_format
  validate :file_size_within_limit
  validate :content_type_allowed

  before_validation :set_default_upload_status, if: :new_record?

  scope :by_category, ->(category_id) { where(file_category_id: category_id) }
  scope :by_content_type, ->(content_type) { where("content_type LIKE ?", "%#{content_type}%") }
  scope :completed, -> { where(upload_status: "completed") }
  scope :pending, -> { where(upload_status: "pending") }
  scope :failed, -> { where(upload_status: "failed") }

  # 파일 크기 제한 (10MB)
  MAX_FILE_SIZE = 10.megabytes

  # 허용되지 않는 파일 형식
  DANGEROUS_CONTENT_TYPES = [
    "application/x-executable",
    "application/x-msdownload",
    "application/octet-stream",
    "application/x-dosexec"
  ].freeze

  def download_url
    # 외부 URL 또는 로컬 파일 경로
    file_url
  end

  def image?
    content_type.start_with?("image/")
  end

  def human_file_size
    case file_size
    when 0..1023
      "#{file_size} bytes"
    when 1024..1048575
      "#{(file_size / 1024.0).round(1)} KB"
    when 1048576..1073741823
      "#{(file_size / 1048576.0).round(1)} MB"
    else
      "#{(file_size / 1073741824.0).round(1)} GB"
    end
  end

  def completed?
    upload_status == "completed"
  end

  def pending?
    upload_status == "pending"
  end

  def failed?
    upload_status == "failed"
  end

  def mark_as_completed!
    update!(upload_status: "completed")
  end

  def mark_as_failed!
    update!(upload_status: "failed")
  end

  private

  def set_default_upload_status
    self.upload_status ||= "pending"
  end

  def file_url_format
    return unless file_url.present?

    # URL 형식 검증
    uri = URI.parse(file_url)
    unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      errors.add(:file_url, "URL은 http 또는 https 형식이어야 합니다")
    end
  rescue URI::InvalidURIError
    errors.add(:file_url, "유효한 URL 형식이 아닙니다")
  end

  def file_size_within_limit
    return unless file_size.present?

    # 전역 파일 크기 제한 검사
    if file_size > MAX_FILE_SIZE
      errors.add(:file_size, "파일 크기는 10MB를 초과할 수 없습니다")
    end

    # 카테고리별 파일 크기 제한 검사
    if file_category.present? && !file_category.allows_file_size?(file_size)
      max_size_mb = (file_category.max_file_size / 1.megabyte).round(1)
      errors.add(:file_size, "이 카테고리의 최대 파일 크기는 #{max_size_mb}MB입니다")
    end
  end

  def content_type_allowed
    return unless content_type.present?

    # 위험한 파일 형식 검사
    if DANGEROUS_CONTENT_TYPES.include?(content_type)
      errors.add(:content_type, "허용되지 않는 파일 형식입니다")
    end

    # 카테고리별 파일 형식 제한 검사
    if file_category.present? && !file_category.allows_content_type?(content_type)
      errors.add(:content_type, "이 카테고리에서 허용되지 않는 파일 형식입니다")
    end
  end
end
