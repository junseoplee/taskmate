class FileCategory < ApplicationRecord
  has_many :file_attachments, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 50 }
  validates :description, length: { maximum: 255 }

  before_save :normalize_name
  serialize :allowed_file_types, type: Array, coder: JSON

  scope :by_name, ->(name) { where("LOWER(name) = ?", name.downcase) }

  def allows_content_type?(content_type)
    return true if allowed_file_types.blank?
    allowed_file_types.include?(content_type)
  end

  def allows_file_size?(file_size)
    return true if max_file_size.nil?
    file_size <= max_file_size
  end

  def files_count
    file_attachments.count
  end

  def total_size
    file_attachments.sum(:file_size)
  end

  def self.find_by_name(name)
    by_name(name).first
  end

  def self.create_defaults
    default_categories = [
      {
        name: "documents",
        description: "문서 파일을 위한 카테고리",
        allowed_file_types: [ "application/pdf", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "text/plain" ],
        max_file_size: 10.megabytes
      },
      {
        name: "images",
        description: "이미지 파일을 위한 카테고리",
        allowed_file_types: [ "image/jpeg", "image/png", "image/gif", "image/webp" ],
        max_file_size: 5.megabytes
      },
      {
        name: "videos",
        description: "비디오 파일을 위한 카테고리",
        allowed_file_types: [ "video/mp4", "video/avi", "video/mov", "video/webm" ],
        max_file_size: 100.megabytes
      },
      {
        name: "others",
        description: "기타 파일을 위한 카테고리",
        allowed_file_types: [],
        max_file_size: 10.megabytes
      }
    ]

    default_categories.each do |category_attrs|
      find_or_create_by(name: category_attrs[:name]) do |category|
        category.description = category_attrs[:description]
        category.allowed_file_types = category_attrs[:allowed_file_types]
        category.max_file_size = category_attrs[:max_file_size]
      end
    end
  end

  private

  def normalize_name
    self.name = name.strip.downcase if name.present?
  end
end
