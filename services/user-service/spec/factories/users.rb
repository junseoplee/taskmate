FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { Faker::Name.name }
    password { 'SecurePass123!' }
    password_confirmation { 'SecurePass123!' }
    
    trait :with_session do
      after(:create) do |user|
        create(:session, user: user)
      end
    end
  end
end