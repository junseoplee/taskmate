require 'rails_helper'

RSpec.describe Api::V1::FileCategoriesController, type: :controller do
  before do
    FileCategory.create_defaults
  end

  let(:valid_attributes) do
    {
      name: 'custom_category',
      description: '사용자 정의 카테고리',
      allowed_file_types: [ 'text/plain', 'text/csv' ],
      max_file_size: 5.megabytes
    }
  end

  let(:invalid_attributes) do
    {
      name: '',
      description: 'a' * 300  # 255자 초과
    }
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful

      data = JSON.parse(response.body)['data']
      expect(data.size).to eq(4)  # 기본 카테고리 4개

      category_names = data.map { |cat| cat['name'] }
      expect(category_names).to include('documents', 'images', 'videos', 'others')
    end

    it 'includes file counts for each category' do
      documents_category = FileCategory.find_by(name: 'documents')
      create_list(:file_attachment, 2, file_category: documents_category)

      get :index
      expect(response).to be_successful

      data = JSON.parse(response.body)['data']
      documents_data = data.find { |cat| cat['name'] == 'documents' }
      expect(documents_data['files_count']).to eq(2)
    end
  end

  describe 'GET #show' do
    let(:category) { FileCategory.find_by(name: 'documents') }

    it 'returns a success response' do
      get :show, params: { id: category.id }
      expect(response).to be_successful

      data = JSON.parse(response.body)['data']
      expect(data['id']).to eq(category.id)
      expect(data['name']).to eq('documents')
    end

    it 'includes category statistics' do
      create_list(:file_attachment, 3, file_category: category, file_size: 1.megabyte)

      get :show, params: { id: category.id }
      expect(response).to be_successful

      data = JSON.parse(response.body)['data']
      expect(data['files_count']).to eq(3)
      expect(data['total_size']).to eq(3.megabytes)
    end

    it 'returns 404 for non-existent category' do
      get :show, params: { id: 99999 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new FileCategory' do
        expect {
          post :create, params: { file_category: valid_attributes }
        }.to change(FileCategory, :count).by(1)
      end

      it 'returns a success response' do
        post :create, params: { file_category: valid_attributes }
        expect(response).to have_http_status(:created)

        data = JSON.parse(response.body)['data']
        expect(data['name']).to eq('custom_category')
        expect(data['allowed_file_types']).to eq([ 'text/plain', 'text/csv' ])
      end
    end

    context 'with invalid params' do
      it 'returns a unprocessable entity response' do
        post :create, params: { file_category: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)

        errors = JSON.parse(response.body)['errors']
        expect(errors).to be_present
        expect(errors['name']).to include("can't be blank")
      end
    end

    context 'with duplicate name' do
      it 'returns validation error' do
        duplicate_attributes = valid_attributes.merge(name: 'documents')

        post :create, params: { file_category: duplicate_attributes }
        expect(response).to have_http_status(:unprocessable_entity)

        errors = JSON.parse(response.body)['errors']
        expect(errors['name']).to include('has already been taken')
      end
    end
  end

  describe 'PATCH #update' do
    let(:category) { create(:file_category) }
    let(:new_attributes) do
      {
        description: '업데이트된 설명',
        max_file_size: 8.megabytes
      }
    end

    it 'updates the file category' do
      patch :update, params: { id: category.id, file_category: new_attributes }
      category.reload
      expect(category.description).to eq('업데이트된 설명')
      expect(category.max_file_size).to eq(8.megabytes)
    end

    it 'returns a success response' do
      patch :update, params: { id: category.id, file_category: new_attributes }
      expect(response).to be_successful

      data = JSON.parse(response.body)['data']
      expect(data['description']).to eq('업데이트된 설명')
    end

    it 'returns 404 for non-existent category' do
      patch :update, params: { id: 99999, file_category: new_attributes }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE #destroy' do
    let!(:category) { create(:file_category) }

    context 'when category has no attached files' do
      it 'destroys the requested file category' do
        expect {
          delete :destroy, params: { id: category.id }
        }.to change(FileCategory, :count).by(-1)
      end

      it 'returns a success response' do
        delete :destroy, params: { id: category.id }
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when category has attached files' do
      before do
        create(:file_attachment, file_category: category)
      end

      it 'nullifies file category references but keeps files' do
        file_attachment = category.file_attachments.first

        delete :destroy, params: { id: category.id }

        file_attachment.reload
        expect(file_attachment.file_category_id).to be_nil
      end
    end

    it 'returns 404 for non-existent category' do
      delete :destroy, params: { id: 99999 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET #file_types' do
    it 'returns allowed file types for a category' do
      images_category = FileCategory.find_by(name: 'images')

      get :file_types, params: { id: images_category.id }
      expect(response).to be_successful

      data = JSON.parse(response.body)['data']
      expect(data['allowed_file_types']).to include('image/jpeg', 'image/png')
    end
  end

  describe 'POST #validate_file' do
    let(:images_category) { FileCategory.find_by(name: 'images') }

    context 'with valid file for category' do
      let(:valid_file_params) do
        {
          content_type: 'image/jpeg',
          file_size: 2.megabytes
        }
      end

      it 'returns validation success' do
        post :validate_file, params: { id: images_category.id, file: valid_file_params }
        expect(response).to be_successful

        data = JSON.parse(response.body)['data']
        expect(data['valid']).to be true
      end
    end

    context 'with invalid file for category' do
      let(:invalid_file_params) do
        {
          content_type: 'application/pdf',
          file_size: 10.megabytes
        }
      end

      it 'returns validation failure' do
        post :validate_file, params: { id: images_category.id, file: invalid_file_params }
        expect(response).to be_successful

        data = JSON.parse(response.body)['data']
        expect(data['valid']).to be false
        expect(data['errors']).to be_present
      end
    end
  end
end
