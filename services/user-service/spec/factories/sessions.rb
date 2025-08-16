FactoryBot.define do
  factory :session do
    association :user
    token { SecureRandom.uuid }
    expires_at { 24.hours.from_now }
  end
end