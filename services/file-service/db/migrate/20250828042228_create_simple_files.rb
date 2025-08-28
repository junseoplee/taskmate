class CreateSimpleFiles < ActiveRecord::Migration[8.0]
  def change
    create_table :simple_files do |t|
      t.string :filename, null: false, limit: 255
      t.string :file_url, null: false, limit: 500
      t.string :file_type, limit: 50
      t.integer :user_id, null: false
      t.integer :file_category_id

      t.timestamps
    end

    add_index :simple_files, :user_id
    add_index :simple_files, :file_category_id
    add_index :simple_files, :file_type
    add_index :simple_files, :created_at
  end
end
