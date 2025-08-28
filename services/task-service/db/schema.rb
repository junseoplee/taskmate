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

ActiveRecord::Schema[8.0].define(version: 2025_08_16_133440) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "tasks", force: :cascade do |t|
    t.string "title", limit: 255, null: false
    t.text "description"
    t.string "status", default: "pending", null: false
    t.string "priority", default: "medium", null: false
    t.integer "user_id", null: false
    t.date "due_date"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "due_date" ], name: "index_tasks_on_due_date"
    t.index [ "priority" ], name: "index_tasks_on_priority"
    t.index [ "status" ], name: "index_tasks_on_status"
    t.index [ "user_id", "priority" ], name: "index_tasks_on_user_id_and_priority"
    t.index [ "user_id", "status" ], name: "index_tasks_on_user_id_and_status"
    t.index [ "user_id" ], name: "index_tasks_on_user_id"
    t.check_constraint "priority::text = ANY (ARRAY['low'::character varying, 'medium'::character varying, 'high'::character varying, 'urgent'::character varying]::text[])", name: "tasks_priority_check"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'in_progress'::character varying, 'completed'::character varying, 'cancelled'::character varying]::text[])", name: "tasks_status_check"
  end
end
