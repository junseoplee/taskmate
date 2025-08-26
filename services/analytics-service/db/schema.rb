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

ActiveRecord::Schema[8.0].define(version: 2025_08_16_143319) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "analytics_events", force: :cascade do |t|
    t.string "event_name", null: false
    t.string "event_type", null: false
    t.string "source_service", null: false
    t.datetime "occurred_at", null: false
    t.json "metadata", default: {}
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type", "occurred_at"], name: "index_analytics_events_on_event_type_and_occurred_at"
    t.index ["event_type"], name: "index_analytics_events_on_event_type"
    t.index ["occurred_at"], name: "index_analytics_events_on_occurred_at"
    t.index ["source_service", "occurred_at"], name: "index_analytics_events_on_source_service_and_occurred_at"
    t.index ["source_service"], name: "index_analytics_events_on_source_service"
    t.index ["user_id"], name: "index_analytics_events_on_user_id"
  end

  create_table "analytics_summaries", force: :cascade do |t|
    t.string "metric_name", null: false
    t.string "metric_type", null: false
    t.decimal "metric_value", precision: 10, scale: 2, null: false
    t.string "time_period", null: false
    t.datetime "calculated_at", null: false
    t.json "metadata", default: {}
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["calculated_at", "metric_name"], name: "index_analytics_summaries_on_calculated_at_and_metric_name"
    t.index ["calculated_at"], name: "index_analytics_summaries_on_calculated_at"
    t.index ["metric_name", "time_period"], name: "index_analytics_summaries_on_metric_name_and_time_period"
    t.index ["metric_name"], name: "index_analytics_summaries_on_metric_name"
    t.index ["metric_type"], name: "index_analytics_summaries_on_metric_type"
    t.index ["time_period"], name: "index_analytics_summaries_on_time_period"
    t.index ["user_id"], name: "index_analytics_summaries_on_user_id"
  end
end
