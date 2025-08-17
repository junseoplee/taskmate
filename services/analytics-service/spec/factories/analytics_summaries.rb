# frozen_string_literal: true

FactoryBot.define do
  factory :analytics_summary do
    metric_name { "tasks_completed" }
    metric_type { "count" }
    metric_value { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    time_period { "daily" }
    calculated_at { Time.current }
    metadata { { "period_start" => Date.current.beginning_of_day } }
    user_id { nil }

    trait :percentage_metric do
      metric_type { "percentage" }
      metric_value { Faker::Number.between(from: 0.0, to: 100.0) }
    end

    trait :average_metric do
      metric_type { "average" }
      metric_name { "task_completion_time" }
    end

    trait :sum_metric do
      metric_type { "sum" }
      metric_name { "total_tasks" }
    end

    trait :hourly do
      time_period { "hourly" }
    end

    trait :weekly do
      time_period { "weekly" }
      metric_name { "weekly_active_users" }
    end

    trait :monthly do
      time_period { "monthly" }
      metric_name { "monthly_growth" }
    end

    trait :with_user do
      user_id { Faker::Number.number(digits: 3) }
    end

    trait :yesterday do
      calculated_at { 1.day.ago }
    end
  end
end