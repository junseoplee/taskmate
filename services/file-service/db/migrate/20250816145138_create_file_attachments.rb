class CreateFileAttachments < ActiveRecord::Migration[8.0]
  def change
    create_table :file_attachments do |t|
      t.string :original_filename, null: false, limit: 255
      t.string :storage_filename, null: false, limit: 255
      t.string :content_type, null: false, limit: 100
      t.bigint :file_size, null: false
      t.references :attachable, polymorphic: true, null: false
      t.references :file_category, null: true, foreign_key: true
      t.string :upload_status, default: 'pending', limit: 20

      t.timestamps
    end
    
    add_index :file_attachments, [:attachable_type, :attachable_id]
    add_index :file_attachments, :storage_filename, unique: true
    add_index :file_attachments, :upload_status
    add_index :file_attachments, :content_type
  end
end
