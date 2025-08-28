class SimpleFile < ApplicationRecord
  belongs_to :file_category, optional: true

  validates :filename, presence: true, length: { maximum: 255 }
  validates :file_url, presence: true, length: { maximum: 500 }
  validates :user_id, presence: true

  scope :by_category, ->(category_id) { where(file_category_id: category_id) }
  scope :by_file_type, ->(file_type) { where(file_type: file_type) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }

  # File type categories
  FILE_TYPES = {
    'document' => %w[pdf doc docx txt html],
    'image' => %w[jpg jpeg png gif bmp],
    'archive' => %w[zip rar 7z tar gz],
    'other' => []
  }.freeze

  def self.determine_file_type(filename)
    return 'other' unless filename.present?

    extension = filename.split('.').last&.downcase
    FILE_TYPES.each do |type, extensions|
      return type if extensions.include?(extension)
    end
    'other'
  end

  def category_name
    file_category&.name || 'Uncategorized'
  end

  def display_filename
    filename.presence || 'Unknown File'
  end

  # Statistics for user
  def self.statistics_for_user(user_id)
    user_files = by_user(user_id)

    total_count = user_files.count

    # File type distribution
    type_stats = user_files.group(:file_type).count

    # Category distribution
    category_stats = user_files.joins(:file_category)
                              .group('file_categories.name')
                              .count

    {
      total_files: total_count,
      file_type_distribution: type_stats,
      category_distribution: category_stats,
      recent_files: user_files.order(created_at: :desc).limit(10)
    }
  end
end
