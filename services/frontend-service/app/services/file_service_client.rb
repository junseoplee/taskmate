class FileServiceClient < BaseServiceClient
  private

  def base_url
    ENV.fetch('FILE_SERVICE_URL', 'http://localhost:3003')
  end

  public

  def get_file_categories
    get("/api/v1/file_categories", headers: auth_headers)
  rescue => e
    handle_error(e, "Failed to fetch file categories")
  end

  def get_user_files(user_id, category_id = nil)
    query_params = { user_id: user_id }
    query_params[:category_id] = category_id if category_id
    
    get("/api/v1/file_attachments", headers: auth_headers, query: query_params)
  rescue => e
    handle_error(e, "Failed to fetch user files")
  end

  def upload_file(user_id, file, category_id = nil)
    post("/api/v1/file_attachments", {
      headers: auth_headers,
      body: {
        user_id: user_id,
        file: file,
        category_id: category_id
      }
    })
  rescue => e
    handle_error(e, "Failed to upload file")
  end

  def delete_file(file_id)
    delete("/api/v1/file_attachments/#{file_id}", headers: auth_headers)
  rescue => e
    handle_error(e, "Failed to delete file")
  end
end