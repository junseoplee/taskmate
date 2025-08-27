FactoryBot.define do
  factory :file_attachment do
    original_filename { Faker::File.file_name }
    file_url { Faker::Internet.url(host: 'example.com', path: "/files/#{Faker::Alphanumeric.alpha(number: 10)}.pdf") }
    content_type { 'application/pdf' }
    file_size { rand(1.kilobyte..5.megabytes) }
    attachable_type { 'Task' }
    attachable_id { rand(1..100) }
    upload_status { 'completed' }

    # storage_filename은 모델에서 자동 생성되므로 제거

    trait :image do
      original_filename { "image_#{rand(1000)}.jpg" }
      file_url { Faker::Internet.url(host: 'example.com', path: "/files/#{Faker::Alphanumeric.alpha(number: 10)}.jpg") }
      content_type { 'image/jpeg' }
    end

    trait :document do
      original_filename { "document_#{rand(1000)}.pdf" }
      file_url { Faker::Internet.url(host: 'example.com', path: "/files/#{Faker::Alphanumeric.alpha(number: 10)}.pdf") }
      content_type { 'application/pdf' }
    end

    trait :text do
      original_filename { "text_#{rand(1000)}.txt" }
      file_url { Faker::Internet.url(host: 'example.com', path: "/files/#{Faker::Alphanumeric.alpha(number: 10)}.txt") }
      content_type { 'text/plain' }
    end

    trait :large do
      file_size { 8.megabytes }
    end

    trait :small do
      file_size { 50.kilobytes }
    end

    trait :uploading do
      upload_status { 'uploading' }
    end

    trait :failed do
      upload_status { 'failed' }
    end
  end
end
