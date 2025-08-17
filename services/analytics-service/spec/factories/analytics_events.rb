# frozen_string_literal: true

FactoryBot.define do
  factory :analytics_event do
    event_name { "task.created" }
    event_type { "task" }
    source_service { "task-service" }
    occurred_at { Time.current }
    metadata { { "task_id" => Faker::Number.number(digits: 3) } }
    user_id { nil }

    trait :task_event do
      event_type { "task" }
      source_service { "task-service" }
    end

    trait :user_event do
      event_type { "user" }
      source_service { "user-service" }
      event_name { "user.login" }
      metadata { { "user_id" => Faker::Number.number(digits: 3) } }
    end

    trait :system_event do
      event_type { "system" }
      source_service { "analytics-service" }
      event_name { "system.health_check" }
      metadata { { "status" => "healthy" } }
    end

    trait :with_user do
      user_id { Faker::Number.number(digits: 3) }
    end

    trait :yesterday do
      occurred_at { 1.day.ago }
    end

    trait :last_week do
      occurred_at { 1.week.ago }
    end
  end
end