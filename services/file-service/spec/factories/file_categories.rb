FactoryBot.define do
  factory :file_category do
    name { Faker::Lorem.word.downcase }
    description { Faker::Lorem.sentence }
    allowed_file_types { [] }
    max_file_size { nil }

    trait :documents do
      name { 'documents' }
      description { '문서 파일을 위한 카테고리' }
      allowed_file_types { [ 'application/pdf', 'application/msword', 'text/plain' ] }
      max_file_size { 10.megabytes }
    end

    trait :images do
      name { 'images' }
      description { '이미지 파일을 위한 카테고리' }
      allowed_file_types { [ 'image/jpeg', 'image/png', 'image/gif' ] }
      max_file_size { 5.megabytes }
    end

    trait :videos do
      name { 'videos' }
      description { '비디오 파일을 위한 카테고리' }
      allowed_file_types { [ 'video/mp4', 'video/avi', 'video/mov' ] }
      max_file_size { 100.megabytes }
    end

    trait :with_restrictions do
      allowed_file_types { [ 'image/jpeg', 'image/png' ] }
      max_file_size { 2.megabytes }
    end
  end
end
