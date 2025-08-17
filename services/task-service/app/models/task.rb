class Task < ApplicationRecord
  # Validations
  validates :title, presence: true, length: { minimum: 1, maximum: 255 }
  validates :description, length: { maximum: 2000 }
  validates :user_id, presence: true
  validates :status, inclusion: { in: %w[pending in_progress completed cancelled] }
  validates :priority, inclusion: { in: %w[low medium high urgent] }
  
  # Custom validation for status transitions
  validate :valid_status_transition, if: :status_changed?

  # Default values
  after_initialize :set_defaults, if: :new_record?
  before_validation :strip_whitespace

  # Callbacks
  before_save :set_completed_at

  # Scopes
  scope :by_status, ->(status) { where(status: status) }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :due_soon, -> { where("due_date <= ?", 3.days.from_now).where("due_date >= ?", Date.current) }
  scope :overdue, -> { where("due_date < ?", Date.current) }

  # Instance methods
  def overdue?
    due_date.present? && due_date < Date.current
  end

  def due_soon?
    due_date.present? && due_date <= 3.days.from_now.to_date && due_date >= Date.current
  end

  def completed?
    status == "completed"
  end

  def can_transition_to?(new_status)
    case status
    when "pending"
      %w[in_progress cancelled].include?(new_status)
    when "in_progress"
      %w[completed cancelled pending].include?(new_status)
    when "completed"
      %w[pending].include?(new_status)
    when "cancelled"
      %w[pending].include?(new_status)
    else
      false
    end
  end

  def update_status!(new_status)
    unless can_transition_to?(new_status)
      errors.add(:status, "Cannot transition from #{status} to #{new_status}")
      raise ActiveRecord::RecordInvalid.new(self)
    end

    # Use update! but mark this as a programmatic status change to skip transition validation
    @programmatic_status_change = true
    result = update!(status: new_status)
    @programmatic_status_change = false
    result
  end

  private

  def set_defaults
    self.status ||= "pending"
    self.priority ||= "medium"
  end

  def strip_whitespace
    self.title = title&.strip
    self.description = description&.strip
  end

  def set_completed_at
    if status == "completed" && !completed_at.present?
      self.completed_at = Time.current
    elsif status != "completed"
      self.completed_at = nil
    end
  end

  def valid_status_transition
    return if @programmatic_status_change
    return unless status_was.present? && status_changed? && persisted?

    unless can_transition_to?(status)
      errors.add(:status, "Cannot transition from #{status_was} to #{status}")
    end
  end
end