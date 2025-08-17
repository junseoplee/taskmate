class CreateFileCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :file_categories do |t|
      t.string :name, null: false, limit: 50
      t.text :description, limit: 255
      t.text :allowed_file_types # JSON array stored as text
      t.bigint :max_file_size # bytes

      t.timestamps
    end

    add_index :file_categories, :name, unique: true
  end
end
