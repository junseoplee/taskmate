class AddConstraintsToTasks < ActiveRecord::Migration[8.0]
  def change
    # Add null constraints
    change_column_null :tasks, :title, false
    change_column_null :tasks, :status, false
    change_column_null :tasks, :priority, false
    change_column_null :tasks, :user_id, false
    
    # Add defaults
    change_column_default :tasks, :status, "pending"
    change_column_default :tasks, :priority, "medium"
    
    # Add length limits
    change_column :tasks, :title, :string, limit: 255
    change_column :tasks, :description, :text, limit: 2000
    
    # Add indexes for better query performance
    add_index :tasks, :user_id
    add_index :tasks, :status
    add_index :tasks, :priority
    add_index :tasks, :due_date
    add_index :tasks, [:user_id, :status]
    add_index :tasks, [:user_id, :priority]
    
    # Add check constraints for enum values
    add_check_constraint :tasks, "status IN ('pending', 'in_progress', 'completed', 'cancelled')", name: "tasks_status_check"
    add_check_constraint :tasks, "priority IN ('low', 'medium', 'high', 'urgent')", name: "tasks_priority_check"
  end
end