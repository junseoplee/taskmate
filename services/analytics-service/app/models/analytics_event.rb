# frozen_string_literal: true

class AnalyticsEvent < ApplicationRecord
  # Validations
  validates :event_name, presence: true
  validates :event_type, presence: true, inclusion: { in: %w[task user system] }
  validates :source_service, presence: true, inclusion: { in: %w[user-service task-service analytics-service file-service] }
  validates :occurred_at, presence: true

  # Associations
  belongs_to :user, optional: true

  # Callbacks
  before_validation :set_occurred_at, if: -> { occurred_at.blank? }

  # Scopes
  scope :by_type, ->(type) { where(event_type: type) }
  scope :by_service, ->(service) { where(source_service: service) }
  scope :by_date_range, ->(start_date, end_date) { where(occurred_at: start_date..end_date) }
  scope :recent, ->(days = 7) { where(occurred_at: days.days.ago..) }
  scope :today, -> { where(occurred_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_week, -> { where(occurred_at: Date.current.beginning_of_week..Date.current.end_of_week) }
  scope :this_month, -> { where(occurred_at: Date.current.beginning_of_month..Date.current.end_of_month) }

  # Instance methods
  def to_metrics
    {
      name: event_name,
      type: event_type,
      service: source_service,
      timestamp: occurred_at.to_i,
      metadata: metadata,
      user_id: user_id
    }
  end

  def task_event?
    event_type == 'task'
  end

  def user_event?
    event_type == 'user'
  end

  def system_event?
    event_type == 'system'
  end

  private

  def set_occurred_at
    self.occurred_at = Time.current
  end
end