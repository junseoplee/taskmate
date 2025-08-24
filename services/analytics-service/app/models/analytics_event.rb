# frozen_string_literal: true

class AnalyticsEvent < ApplicationRecord
  # Validations
  validates :event_name, presence: true
  validates :event_type, presence: true, inclusion: { in: %w[task user system] }
  validates :source_service, presence: true, inclusion: { in: %w[user-service task-service analytics-service file-service] }
  validates :occurred_at, presence: true
  validates :user_id, presence: true, numericality: { only_integer: true }

  # Associations
  # Note: user 관계는 다른 서비스의 User이므로 optional로 유지

  # Callbacks
  before_validation :set_occurred_at, if: -> { occurred_at.blank? }

  # JSON 컬럼은 Rails 8에서 자동으로 직렬화됨 - serialize 불필요

  # Scopes
  scope :by_type, ->(type) { where(event_type: type) }
  scope :by_service, ->(service) { where(source_service: service) }
  scope :by_date_range, ->(start_date, end_date) { where(occurred_at: start_date..end_date) }
  scope :recent, ->(days = 7) { where(occurred_at: days.days.ago..) }
  scope :today, -> { where(occurred_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_week, -> { where(occurred_at: Date.current.beginning_of_week..Date.current.end_of_week) }
  scope :this_month, -> { where(occurred_at: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }

  # 통계 계산을 위한 클래스 메서드들
  def self.task_completion_rate(start_date = nil, end_date = nil)
    events = by_date_range(start_date || 1.month.ago, end_date || Time.current)

    created_events = events.where(event_name: "task_created").count
    completed_events = events.where(event_name: "task_completed").count

    return 0.0 if created_events.zero?
    (completed_events.to_f / created_events * 100).round(2)
  end

  def self.completion_trend_data(days = 30)
    end_date = Date.current
    start_date = end_date - days.days

    (start_date..end_date).map do |date|
      completed_count = where(event_name: "task_completed")
                       .where(occurred_at: date.beginning_of_day..date.end_of_day)
                       .count

      {
        date: date.strftime("%Y-%m-%d"),
        completed_tasks: completed_count
      }
    end
  end

  def self.priority_distribution
    # metadata에서 우선순위 정보 추출하여 집계
    # 실제 구현에서는 Task Service에서 받은 데이터 기반으로 계산
    {
      "high" => where("metadata ->> 'priority' = ?", "high").count,
      "medium" => where("metadata ->> 'priority' = ?", "medium").count,
      "low" => where("metadata ->> 'priority' = ?", "low").count
    }
  end

  def self.user_activity_summary(user_id)
    events = by_user(user_id).recent(30).order(occurred_at: :desc)

    {
      total_events: events.count,
      tasks_created: events.where(event_name: "task_created").count,
      tasks_completed: events.where(event_name: "task_completed").count,
      files_uploaded: events.where(event_name: "file_uploaded").count,
      last_activity: events.first&.occurred_at
    }
  end

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
    event_type == "task"
  end

  def user_event?
    event_type == "user"
  end

  def system_event?
    event_type == "system"
  end

  private

  def set_occurred_at
    self.occurred_at = Time.current
  end
end
