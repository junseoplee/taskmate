class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.string :title
      t.text :description
      t.string :status
      t.string :priority
      t.integer :user_id
      t.date :due_date
      t.datetime :completed_at

      t.timestamps
    end
  end
end
