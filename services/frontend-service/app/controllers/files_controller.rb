class FilesController < ApplicationController
  def index
    @files_data = fetch_files_data
    @categories = fetch_categories
  end

  def categories
    render json: fetch_categories
  end

  def create_category
    file_client = FileServiceClient.new
    result = file_client.create_category(current_user['id'], category_params)
    
    if result['success']
      redirect_to files_path, notice: 'Category created successfully!'
    else
      flash[:alert] = result['message'] || 'Failed to create category.'
      redirect_to files_path
    end
  end

  def upload
    file_client = FileServiceClient.new
    result = file_client.upload_file(current_user['id'], file_params)
    
    if result['success']
      if request.xhr?
        render json: { 
          success: true, 
          message: 'File uploaded successfully!',
          file: result['file']
        }
      else
        redirect_to files_path, notice: 'File uploaded successfully!'
      end
    else
      if request.xhr?
        render json: { 
          success: false, 
          message: result['message'] || 'Failed to upload file.'
        }
      else
        flash[:alert] = result['message'] || 'Failed to upload file.'
        redirect_to files_path
      end
    end
  end

  def download
    file_client = FileServiceClient.new
    result = file_client.get_file_download_url(params[:id])
    
    if result['success']
      redirect_to result['download_url'], allow_other_host: true
    else
      redirect_to files_path, alert: result['message'] || 'Failed to download file.'
    end
  end

  def destroy
    file_client = FileServiceClient.new
    result = file_client.delete_file(params[:id])
    
    if result['success']
      redirect_to files_path, notice: 'File deleted successfully!'
    else
      redirect_to files_path, alert: result['message'] || 'Failed to delete file.'
    end
  end

  private

  def fetch_files_data
    file_client = FileServiceClient.new
    
    begin
      response = file_client.get_user_files(current_user['id'], filter_params)
      
      if response['success']
        {
          files: response['files'] || [],
          pagination: response['pagination'] || {},
          filters: filter_params
        }
      else
        {
          files: [],
          pagination: {},
          filters: filter_params,
          error: response['message']
        }
      end
    rescue => e
      Rails.logger.error "File data fetch error: #{e.message}"
      {
        files: [],
        pagination: {},
        filters: filter_params,
        error: 'Unable to load file data.'
      }
    end
  end

  def fetch_categories
    file_client = FileServiceClient.new
    
    begin
      response = file_client.get_user_categories(current_user['id'])
      response['success'] ? (response['categories'] || []) : []
    rescue => e
      Rails.logger.error "Category fetch error: #{e.message}"
      []
    end
  end

  def file_params
    params.permit(:file, :task_id, :category_id, :description)
  end

  def category_params
    params.require(:category).permit(:name, :color)
  end

  def filter_params
    params.permit(:category_id, :file_type, :page, :per_page, :search).to_h.with_defaults(
      page: 1,
      per_page: 20
    )
  end
end