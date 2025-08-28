class FileServiceClient < BaseServiceClient
  def base_url
    ENV.fetch("FILE_SERVICE_URL", "http://localhost:3003")
  end

  def get_file_categories
    get("/api/v1/file_categories", headers: auth_headers)
  rescue => e
    handle_error(e, "Failed to fetch file categories")
  end

  def get_user_categories(user_id, session_token: nil)
    response = get("/api/v1/file_categories", headers: auth_headers(session_token: session_token), query: { user_id: user_id })

    if response && response["data"]
      {
        "success" => true,
        "categories" => response["data"]
      }
    else
      {
        "success" => false,
        "categories" => []
      }
    end
  rescue => e
    handle_error(e, "Failed to fetch user categories")
  end

  def get_user_files(user_id, filters = {}, session_token: nil)
    query_params = filters.merge({ user_id: user_id })

    response = get("/api/v1/file_attachments", headers: auth_headers(session_token: session_token), query: query_params)

    if response && response["data"]
      {
        "success" => true,
        "files" => response["data"]["items"] || [],
        "pagination" => response["data"]["pagination"]
      }
    else
      {
        "success" => false,
        "files" => [],
        "message" => "Failed to fetch files"
      }
    end
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

  def create_file_attachment(file_data, session_token: nil)
    post("/api/v1/file_attachments", {
      headers: auth_headers(session_token: session_token),
      body: { file_attachment: file_data }
    })
  rescue => e
    handle_error(e, "Failed to create file attachment")
  end

  def delete_file(file_id, session_token: nil)
    delete("/api/v1/file_attachments/#{file_id}", headers: auth_headers(session_token: session_token))
  rescue => e
    handle_error(e, "Failed to delete file")
  end

  def get_file_stats(user_id, session_token: nil)
    # This method doesn't exist in the File Service API yet
    # Return default stats for now
    {
      "success" => true,
      "data" => {
        "total_files" => 0,
        "total_size" => 0
      }
    }
  end

  def get_file_download_url(file_id, session_token: nil)
    response = get("/api/v1/file_attachments/#{file_id}", headers: auth_headers(session_token: session_token))

    if response && response["data"]
      {
        "success" => true,
        "download_url" => response["data"]["download_url"] || response["data"]["file_url"]
      }
    else
      {
        "success" => false,
        "message" => "Failed to get download URL"
      }
    end
  rescue => e
    handle_error(e, "Failed to get download URL")
  end

  def create_category(user_id, category_data, session_token: nil)
    post("/api/v1/file_categories", {
      headers: auth_headers(session_token: session_token),
      body: {
        file_category: category_data.merge(user_id: user_id)
      }
    })
  rescue => e
    handle_error(e, "Failed to create category")
  end

  # New Simple Files API methods
  def create_simple_file(file_data, session_token: nil)
    post("/api/v1/simple_files", {
      headers: auth_headers(session_token: session_token),
      body: { simple_file: file_data }
    })
  rescue => e
    handle_error(e, "Failed to create simple file")
  end

  def get_simple_files(user_id, filters = {}, session_token: nil)
    query_params = filters.merge({ user_id: user_id })

    response = get("/api/v1/simple_files", headers: auth_headers(session_token: session_token), query: query_params)

    if response && response["data"]
      {
        "success" => true,
        "files" => response["data"]["files"] || [],
        "pagination" => response["data"]["pagination"]
      }
    else
      {
        "success" => false,
        "files" => [],
        "message" => "Failed to fetch files"
      }
    end
  rescue => e
    handle_error(e, "Failed to fetch simple files")
  end

  def delete_simple_file(file_id, session_token: nil)
    delete("/api/v1/simple_files/#{file_id}", headers: auth_headers(session_token: session_token))
  rescue => e
    handle_error(e, "Failed to delete simple file")
  end

  def get_simple_file_stats(user_id, session_token: nil)
    response = get("/api/v1/simple_files/statistics", headers: auth_headers(session_token: session_token), query: { user_id: user_id })

    if response && response["data"]
      {
        "success" => true,
        "data" => response["data"]["statistics"] || {}
      }
    else
      {
        "success" => false,
        "data" => { "total_files" => 0 }
      }
    end
  rescue => e
    handle_error(e, "Failed to fetch simple file stats")
  end
end
