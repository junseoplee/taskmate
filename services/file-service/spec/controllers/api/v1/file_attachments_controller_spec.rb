require 'rails_helper'

RSpec.describe Api::V1::FileAttachmentsController, type: :controller do
  before do
    FileCategory.create_defaults
  end

  let(:document_category) { FileCategory.find_by(name: 'documents') }
  let(:valid_attributes) do
    {
      original_filename: 'test.pdf',
      file_url: 'https://example.com/files/test.pdf',
      content_type: 'application/pdf',
      file_size: 1.megabyte,
      attachable_type: 'Task',
      attachable_id: 1,
      file_category_id: document_category.id
    }
  end

  let(:invalid_attributes) do
    {
      original_filename: '',
      content_type: '',
      file_size: -1
    }
  end

  describe 'GET #index' do
    before do
      create_list(:file_attachment, 3, file_category: document_category)
    end

    it 'returns a success response' do
      get :index
      expect(response).to be_successful
      expect(JSON.parse(response.body)['data']['items'].size).to eq(3)
    end

    it 'filters by category' do
      image_category = FileCategory.find_by(name: 'images')
      create(:file_attachment, :image, file_category: image_category)

      get :index, params: { category_id: image_category.id }
      expect(response).to be_successful

      data = JSON.parse(response.body)['data']['items']
      expect(data.size).to eq(1)
      expect(data.first['file_category_id']).to eq(image_category.id)
    end

    it 'filters by content type' do
      image_category = FileCategory.find_by(name: 'images')
      create(:file_attachment, :image, file_category: image_category)

      get :index, params: { content_type: 'image' }
      expect(response).to be_successful

      data = JSON.parse(response.body)['data']['items']
      expect(data.size).to eq(1)
      expect(data.first['content_type']).to include('image')
    end

    it 'filters by attachable type and id' do
      create(:file_attachment, attachable_type: 'User', attachable_id: 99)

      get :index, params: { attachable_type: 'User', attachable_id: 99 }
      expect(response).to be_successful

      data = JSON.parse(response.body)['data']['items']
      expect(data.size).to eq(1)
      expect(data.first['attachable_type']).to eq('User')
      expect(data.first['attachable_id']).to eq(99)
    end
  end

  describe 'GET #show' do
    let(:file_attachment) { create(:file_attachment) }

    it 'returns a success response' do
      get :show, params: { id: file_attachment.id }
      expect(response).to be_successful

      data = JSON.parse(response.body)['data']
      expect(data['id']).to eq(file_attachment.id)
      expect(data['original_filename']).to eq(file_attachment.original_filename)
    end

    it 'returns 404 for non-existent file' do
      get :show, params: { id: 99999 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new FileAttachment' do
        expect {
          post :create, params: { file_attachment: valid_attributes }
        }.to change(FileAttachment, :count).by(1)
      end

      it 'returns a success response' do
        post :create, params: { file_attachment: valid_attributes }
        expect(response).to have_http_status(:created)

        data = JSON.parse(response.body)['data']
        expect(data['original_filename']).to eq('test.pdf')
        expect(data['file_url']).to eq('https://example.com/files/test.pdf')
        expect(data['download_url']).to eq('https://example.com/files/test.pdf')
      end
    end

    context 'with invalid params' do
      it 'returns a unprocessable entity response' do
        post :create, params: { file_attachment: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)

        errors = JSON.parse(response.body)['errors']
        expect(errors).to be_present
      end
    end

    context 'with file size exceeding category limit' do
      it 'returns validation error' do
        large_file_attributes = valid_attributes.merge(file_size: 15.megabytes)

        post :create, params: { file_attachment: large_file_attributes }
        expect(response).to have_http_status(:unprocessable_entity)

        errors = JSON.parse(response.body)['errors']
        expect(errors['file_size']).to include('이 카테고리의 최대 파일 크기는 10MB입니다')
      end
    end

    context 'with disallowed content type for category' do
      let(:image_category) { FileCategory.find_by(name: 'images') }

      it 'returns validation error' do
        invalid_type_attributes = valid_attributes.merge(
          content_type: 'application/pdf',
          file_category_id: image_category.id
        )

        post :create, params: { file_attachment: invalid_type_attributes }
        expect(response).to have_http_status(:unprocessable_entity)

        errors = JSON.parse(response.body)['errors']
        expect(errors['content_type']).to include('이 카테고리에서 허용되지 않는 파일 형식입니다')
      end
    end
  end

  describe 'PATCH #update' do
    let(:file_attachment) { create(:file_attachment) }
    let(:new_attributes) { { upload_status: 'completed' } }

    it 'updates the file attachment' do
      patch :update, params: { id: file_attachment.id, file_attachment: new_attributes }
      file_attachment.reload
      expect(file_attachment.upload_status).to eq('completed')
    end

    it 'returns a success response' do
      patch :update, params: { id: file_attachment.id, file_attachment: new_attributes }
      expect(response).to be_successful

      data = JSON.parse(response.body)['data']
      expect(data['upload_status']).to eq('completed')
    end

    it 'returns 404 for non-existent file' do
      patch :update, params: { id: 99999, file_attachment: new_attributes }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE #destroy' do
    let!(:file_attachment) { create(:file_attachment) }

    it 'destroys the requested file attachment' do
      expect {
        delete :destroy, params: { id: file_attachment.id }
      }.to change(FileAttachment, :count).by(-1)
    end

    it 'returns a success response' do
      delete :destroy, params: { id: file_attachment.id }
      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 for non-existent file' do
      delete :destroy, params: { id: 99999 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #upload_complete' do
    let(:file_attachment) { create(:file_attachment, upload_status: 'pending') }

    it 'marks file as completed' do
      post :upload_complete, params: { id: file_attachment.id }
      file_attachment.reload
      expect(file_attachment.upload_status).to eq('completed')
    end

    it 'returns success response' do
      post :upload_complete, params: { id: file_attachment.id }
      expect(response).to be_successful

      data = JSON.parse(response.body)['data']
      expect(data['upload_status']).to eq('completed')
    end
  end

  describe 'POST #upload_failed' do
    let(:file_attachment) { create(:file_attachment, upload_status: 'pending') }

    it 'marks file as failed' do
      post :upload_failed, params: { id: file_attachment.id }
      file_attachment.reload
      expect(file_attachment.upload_status).to eq('failed')
    end

    it 'returns success response' do
      post :upload_failed, params: { id: file_attachment.id }
      expect(response).to be_successful

      data = JSON.parse(response.body)['data']
      expect(data['upload_status']).to eq('failed')
    end
  end
end
