FactoryBot.define do
  factory :task do
    sequence(:title) { |n| "Task #{n}" }
    description { Faker::Lorem.paragraph(sentence_count: 2) }
    status { "pending" }
    priority { "medium" }
    user_id { 1 }
    due_date { nil }

    trait :with_due_date do
      due_date { 3.days.from_now }
    end

    trait :overdue do
      due_date { 2.days.ago }
    end

    trait :due_soon do
      due_date { 1.day.from_now }
    end

    trait :high_priority do
      priority { "high" }
    end

    trait :urgent do
      priority { "urgent" }
    end

    trait :low_priority do
      priority { "low" }
    end

    trait :in_progress do
      status { "in_progress" }
    end

    trait :completed do
      status { "completed" }
      completed_at { 1.hour.ago }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :with_long_description do
      description { Faker::Lorem.paragraph(sentence_count: 10) }
    end
  end
end
