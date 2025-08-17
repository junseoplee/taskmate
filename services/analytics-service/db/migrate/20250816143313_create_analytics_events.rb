class CreateAnalyticsEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :analytics_events do |t|
      t.string :event_name, null: false
      t.string :event_type, null: false
      t.string :source_service, null: false
      t.datetime :occurred_at, null: false
      t.json :metadata, default: {}
      t.integer :user_id

      t.timestamps

      # Indexes for better query performance
      t.index :event_type
      t.index :source_service
      t.index :occurred_at
      t.index :user_id
      t.index [ :event_type, :occurred_at ]
      t.index [ :source_service, :occurred_at ]
    end
  end
end
