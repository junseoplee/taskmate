# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_16_145138) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "file_attachments", force: :cascade do |t|
    t.string "original_filename", limit: 255, null: false
    t.string "storage_filename", limit: 255, null: false
    t.string "content_type", limit: 100, null: false
    t.bigint "file_size", null: false
    t.string "attachable_type", null: false
    t.bigint "attachable_id", null: false
    t.bigint "file_category_id"
    t.string "upload_status", limit: 20, default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "attachable_type", "attachable_id" ], name: "index_file_attachments_on_attachable"
    t.index [ "attachable_type", "attachable_id" ], name: "index_file_attachments_on_attachable_type_and_attachable_id"
    t.index [ "content_type" ], name: "index_file_attachments_on_content_type"
    t.index [ "file_category_id" ], name: "index_file_attachments_on_file_category_id"
    t.index [ "storage_filename" ], name: "index_file_attachments_on_storage_filename", unique: true
    t.index [ "upload_status" ], name: "index_file_attachments_on_upload_status"
  end

  create_table "file_categories", force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.text "description"
    t.text "allowed_file_types"
    t.bigint "max_file_size"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "name" ], name: "index_file_categories_on_name", unique: true
  end

  add_foreign_key "file_attachments", "file_categories"
end
