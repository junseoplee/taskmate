require 'rails_helper'

RSpec.describe FileAttachment, type: :model do
  describe 'associations' do
    it { should belong_to(:attachable).optional }
    it { should belong_to(:file_category).optional }
  end

  describe 'validations' do
    subject { build(:file_attachment) }

    it { should validate_presence_of(:original_filename) }
    it { should validate_presence_of(:content_type) }
    it { should validate_presence_of(:file_size) }
    it { should validate_presence_of(:attachable_type) }
    it { should validate_presence_of(:attachable_id) }

    it { should validate_numericality_of(:file_size).is_greater_than(0) }
    it { should validate_length_of(:original_filename).is_at_most(255) }
    it { should validate_length_of(:content_type).is_at_most(100) }
  end

  describe 'polymorphic association' do
    it 'can be attached to different models' do
      # Task 모델과 연관된 첨부파일
      task_attachment = build(:file_attachment,
                              attachable_type: 'Task',
                              attachable_id: 1)
      expect(task_attachment.attachable_type).to eq('Task')
      expect(task_attachment.attachable_id).to eq(1)

      # User 모델과 연관된 첨부파일
      user_attachment = build(:file_attachment,
                              attachable_type: 'User',
                              attachable_id: 2)
      expect(user_attachment.attachable_type).to eq('User')
      expect(user_attachment.attachable_id).to eq(2)
    end
  end

  describe 'file operations' do
    let(:file_attachment) { create(:file_attachment) }

    it 'has a valid file URL' do
      expect(file_attachment.file_url).to be_present
      expect(file_attachment.file_url).to match(/^https?:\/\/.+/)
    end

    it 'provides download URL' do
      expect(file_attachment.download_url).to eq(file_attachment.file_url)
    end

    it 'can determine if it is an image' do
      image_attachment = create(:file_attachment, content_type: 'image/jpeg')
      text_attachment = create(:file_attachment, content_type: 'text/plain')

      expect(image_attachment.image?).to be true
      expect(text_attachment.image?).to be false
    end

    it 'provides human readable file size' do
      small_file = create(:file_attachment, file_size: 1024)
      large_file = create(:file_attachment, file_size: 1_048_576)

      expect(small_file.human_file_size).to eq('1.0 KB')
      expect(large_file.human_file_size).to eq('1.0 MB')
    end
  end

  describe 'file category filtering' do
    let(:document_category) { create(:file_category, name: 'documents') }
    let(:image_category) { create(:file_category, name: 'images') }

    before do
      create(:file_attachment, file_category: document_category, content_type: 'application/pdf')
      create(:file_attachment, file_category: image_category, content_type: 'image/jpeg')
      create(:file_attachment, file_category: nil, content_type: 'text/plain')
    end

    it 'can filter by category' do
      expect(FileAttachment.by_category(document_category.id).count).to eq(1)
      expect(FileAttachment.by_category(image_category.id).count).to eq(1)
    end

    it 'can filter by content type' do
      expect(FileAttachment.by_content_type('image').count).to eq(1)
      expect(FileAttachment.by_content_type('application').count).to eq(1)
    end
  end

  describe 'file size validation' do
    it 'rejects files larger than maximum size' do
      large_file = build(:file_attachment, file_size: 11.megabytes)
      expect(large_file).not_to be_valid
      expect(large_file.errors[:file_size]).to include('파일 크기는 10MB를 초과할 수 없습니다')
    end

    it 'accepts files within size limit' do
      normal_file = build(:file_attachment, file_size: 5.megabytes)
      expect(normal_file).to be_valid
    end
  end

  describe 'security validations' do
    it 'rejects dangerous file types' do
      dangerous_file = build(:file_attachment,
                             content_type: 'application/x-executable',
                             original_filename: 'virus.exe')
      expect(dangerous_file).not_to be_valid
      expect(dangerous_file.errors[:content_type]).to include('허용되지 않는 파일 형식입니다')
    end

    it 'accepts safe file types' do
      safe_file = build(:file_attachment,
                        content_type: 'image/jpeg',
                        original_filename: 'photo.jpg')
      expect(safe_file).to be_valid
    end
  end
end
