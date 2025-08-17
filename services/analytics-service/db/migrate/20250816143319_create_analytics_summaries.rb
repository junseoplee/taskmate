class CreateAnalyticsSummaries < ActiveRecord::Migration[8.0]
  def change
    create_table :analytics_summaries do |t|
      t.string :metric_name, null: false
      t.string :metric_type, null: false
      t.decimal :metric_value, precision: 10, scale: 2, null: false
      t.string :time_period, null: false
      t.datetime :calculated_at, null: false
      t.json :metadata, default: {}
      t.integer :user_id

      t.timestamps

      # Indexes for better query performance
      t.index :metric_name
      t.index :metric_type
      t.index :time_period
      t.index :calculated_at
      t.index :user_id
      t.index [:metric_name, :time_period]
      t.index [:calculated_at, :metric_name]
    end
  end
end
