class ModifyFileAttachmentForUrlStorage < ActiveRecord::Migration[8.0]
  def change
    # Make storage_filename nullable since we're switching to URL-based storage
    change_column_null :file_attachments, :storage_filename, true

    # Update existing records with null file_url to have placeholder URLs
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE file_attachments#{' '}
          SET file_url = 'https://example.com/placeholder/' || COALESCE(storage_filename, 'file')
          WHERE file_url IS NULL;
        SQL
      end
    end

    # Add NOT NULL constraint to file_url since it's now required
    change_column_null :file_attachments, :file_url, false
  end
end
