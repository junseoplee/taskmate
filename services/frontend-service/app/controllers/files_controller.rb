class FilesController < ApplicationController
  def index
    @files_data = fetch_simple_files_data
    @files = @files_data[:files]
    @categories = fetch_categories
    @file_stats = fetch_simple_file_stats
  end

  def categories
    render json: fetch_categories
  end

  def create_category
    file_client = FileServiceClient.new
    result = file_client.create_category(current_user["id"], category_params)

    if result["success"]
      redirect_to files_path, notice: "Category created successfully!"
    else
      flash[:alert] = result["message"] || "Failed to create category."
      redirect_to files_path
    end
  end

  def upload
    file_client = FileServiceClient.new
    session_token = current_session_token

    # Create file attachment metadata
    file_data = params[:file_attachment]
    result = file_client.create_file_attachment(file_data, session_token: session_token)

    if result["data"] || result["success"]
      if request.xhr?
        render json: {
          success: true,
          message: "File uploaded successfully!",
          file: result["data"]
        }
      else
        redirect_to files_path, notice: "File uploaded successfully!"
      end
    else
      if request.xhr?
        render json: {
          success: false,
          message: result["message"] || "Failed to upload file."
        }, status: :unprocessable_entity
      else
        flash[:alert] = result["message"] || "Failed to upload file."
        redirect_to files_path
      end
    end
  rescue => e
    Rails.logger.error "File upload error: #{e.message}"
    if request.xhr?
      render json: {
        success: false,
        message: "Upload failed due to server error."
      }, status: :internal_server_error
    else
      flash[:alert] = "Upload failed due to server error."
      redirect_to files_path
    end
  end

  def download
    file_client = FileServiceClient.new
    result = file_client.get_file_download_url(params[:id])

    if result["success"]
      redirect_to result["download_url"], allow_other_host: true
    else
      redirect_to files_path, alert: result["message"] || "Failed to download file."
    end
  end

  def destroy
    file_client = FileServiceClient.new
    result = file_client.delete_simple_file(params[:id], session_token: current_session_token)

    if result["success"]
      redirect_to files_path, notice: "File deleted successfully!"
    else
      redirect_to files_path, alert: result["message"] || "Failed to delete file."
    end
  end

  def add_url
    file_client = FileServiceClient.new
    session_token = current_session_token

    Rails.logger.info "=== Add URL File Debug ==="
    Rails.logger.info "Parameters: #{params.inspect}"
    Rails.logger.info "Session token: #{session_token}"

    # Simple file data - no complex content-type inference
    file_data = {
      filename: params[:filename],
      file_url: params[:file_url],
      user_id: current_user["id"],
      file_category_id: params[:category_id].present? ? params[:category_id].to_i : 1
    }

    Rails.logger.info "File data to send: #{file_data.inspect}"

    result = file_client.create_simple_file(file_data, session_token: session_token)

    Rails.logger.info "File service result: #{result.inspect}"

    if result["data"] || result["success"]
      if request.xhr?
        render json: {
          success: true,
          message: "URL file added successfully!",
          file: result["data"]
        }
      else
        redirect_to files_path, notice: "URL file added successfully!"
      end
    else
      if request.xhr?
        render json: {
          success: false,
          message: result["message"] || "Failed to add URL file."
        }, status: :unprocessable_entity
      else
        flash[:alert] = result["message"] || "Failed to add URL file."
        redirect_to files_path
      end
    end
  rescue => e
    Rails.logger.error "URL file add error: #{e.message}"
    if request.xhr?
      render json: {
        success: false,
        message: "Failed to add URL file due to server error."
      }, status: :internal_server_error
    else
      flash[:alert] = "Failed to add URL file due to server error."
      redirect_to files_path
    end
  end

  private

  def fetch_simple_files_data
    file_client = FileServiceClient.new

    begin
      response = file_client.get_simple_files(current_user["id"], filter_params, session_token: current_session_token)

      if response["success"]
        {
          files: response["files"] || [],
          pagination: response["pagination"] || {},
          filters: filter_params
        }
      else
        {
          files: [],
          pagination: {},
          filters: filter_params,
          error: response["message"]
        }
      end
    rescue => e
      Rails.logger.error "Simple file data fetch error: #{e.message}"
      {
        files: [],
        pagination: {},
        filters: filter_params,
        error: "Unable to load file data."
      }
    end
  end

  def fetch_categories
    file_client = FileServiceClient.new

    begin
      response = file_client.get_user_categories(current_user["id"], session_token: current_session_token)
      response["success"] ? (response["categories"] || []) : []
    rescue => e
      Rails.logger.error "Category fetch error: #{e.message}"
      []
    end
  end

  def fetch_simple_file_stats
    file_client = FileServiceClient.new

    begin
      response = file_client.get_simple_file_stats(current_user["id"], session_token: current_session_token)
      if response["success"]
        response["data"] || { total_files: 0 }
      else
        { total_files: 0 }
      end
    rescue => e
      Rails.logger.error "Simple file stats fetch error: #{e.message}"
      { total_files: 0 }
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
