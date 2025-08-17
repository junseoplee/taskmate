# frozen_string_literal: true

class AnalyticsSummary < ApplicationRecord
  # Validations
  validates :metric_name, presence: true
  validates :metric_type, presence: true, inclusion: { in: %w[count average sum percentage] }
  validates :metric_value, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :time_period, presence: true, inclusion: { in: %w[hourly daily weekly monthly] }
  validates :calculated_at, presence: true

  # Associations
  belongs_to :user, optional: true

  # Callbacks
  before_validation :set_calculated_at, if: -> { calculated_at.blank? }

  # Scopes
  scope :by_metric, ->(metric) { where(metric_name: metric) }
  scope :by_type, ->(type) { where(metric_type: type) }
  scope :by_period, ->(period) { where(time_period: period) }
  scope :recent, ->(days = 30) { where(calculated_at: days.days.ago..) }
  scope :today, -> { where(calculated_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_week, -> { where(calculated_at: Date.current.beginning_of_week..Date.current.end_of_week) }
  scope :this_month, -> { where(calculated_at: Date.current.beginning_of_month..Date.current.end_of_month) }

  # Instance methods
  def formatted_value
    case metric_type
    when 'percentage'
      "#{metric_value}%"
    when 'count', 'sum'
      metric_value.to_i.to_s
    when 'average'
      format('%.2f', metric_value)
    else
      metric_value.to_s
    end
  end

  def to_chart_data
    {
      name: metric_name,
      value: metric_value.to_f,
      period: time_period,
      date: calculated_at.to_date,
      formatted_value: formatted_value
    }
  end

  def percentage?
    metric_type == 'percentage'
  end

  def count?
    metric_type == 'count'
  end

  def average?
    metric_type == 'average'
  end

  def sum?
    metric_type == 'sum'
  end

  private

  def set_calculated_at
    self.calculated_at = Time.current
  end
end