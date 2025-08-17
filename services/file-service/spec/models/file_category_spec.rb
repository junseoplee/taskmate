require 'rails_helper'

RSpec.describe FileCategory, type: :model do
  describe 'associations' do
    it { should have_many(:file_attachments).dependent(:nullify) }
  end

  describe 'validations' do
    subject { build(:file_category) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
    it { should validate_length_of(:name).is_at_most(50) }
    it { should validate_length_of(:description).is_at_most(255) }
  end

  describe 'name normalization' do
    it 'normalizes name to lowercase' do
      category = create(:file_category, name: 'DOCUMENTS')
      expect(category.name).to eq('documents')
    end

    it 'strips whitespace from name' do
      category = create(:file_category, name: '  images  ')
      expect(category.name).to eq('images')
    end
  end

  describe 'allowed file types' do
    let(:category) { create(:file_category, allowed_file_types: [ 'image/jpeg', 'image/png' ]) }

    it 'can check if a content type is allowed' do
      expect(category.allows_content_type?('image/jpeg')).to be true
      expect(category.allows_content_type?('image/png')).to be true
      expect(category.allows_content_type?('text/plain')).to be false
    end

    it 'allows all types when allowed_file_types is empty' do
      category_without_restrictions = create(:file_category, allowed_file_types: [])
      expect(category_without_restrictions.allows_content_type?('text/plain')).to be true
      expect(category_without_restrictions.allows_content_type?('application/pdf')).to be true
    end
  end

  describe 'max file size' do
    let(:category) { create(:file_category, max_file_size: 5.megabytes) }

    it 'can check if a file size is within limit' do
      expect(category.allows_file_size?(3.megabytes)).to be true
      expect(category.allows_file_size?(7.megabytes)).to be false
    end

    it 'has no size limit when max_file_size is nil' do
      category_without_limit = create(:file_category, max_file_size: nil)
      expect(category_without_limit.allows_file_size?(100.megabytes)).to be true
    end
  end

  describe 'default categories' do
    it 'creates default categories' do
      FileCategory.create_defaults

      expect(FileCategory.find_by(name: 'documents')).to be_present
      expect(FileCategory.find_by(name: 'images')).to be_present
      expect(FileCategory.find_by(name: 'videos')).to be_present
      expect(FileCategory.find_by(name: 'others')).to be_present
    end

    it 'does not duplicate default categories' do
      FileCategory.create_defaults
      initial_count = FileCategory.count

      FileCategory.create_defaults
      expect(FileCategory.count).to eq(initial_count)
    end
  end

  describe 'category statistics' do
    let(:category) { create(:file_category) }

    before do
      create_list(:file_attachment, 3, file_category: category)
      create_list(:file_attachment, 2) # without category
    end

    it 'counts files in category' do
      expect(category.files_count).to eq(3)
    end

    it 'calculates total size of files in category' do
      category.file_attachments.each { |file| file.update(file_size: 1.megabyte) }
      expect(category.total_size).to eq(3.megabytes)
    end
  end

  describe 'category lookup' do
    before do
      create(:file_category, name: 'documents')
      create(:file_category, name: 'images')
    end

    it 'finds category by name case-insensitively' do
      expect(FileCategory.find_by_name('DOCUMENTS')).to be_present
      expect(FileCategory.find_by_name('Images')).to be_present
      expect(FileCategory.find_by_name('videos')).to be_nil
    end
  end
end
