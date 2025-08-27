class AddFileUrlToFileAttachments < ActiveRecord::Migration[8.0]
  def change
    add_column :file_attachments, :file_url, :string
  end
end
