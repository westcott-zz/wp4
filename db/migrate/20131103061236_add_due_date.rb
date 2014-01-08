class AddDueDate < ActiveRecord::Migration
  def change
    add_column :tickets, :due_at, :datetime
    add_column :tickets, :completed_at, :datetime
    add_column :tickets, :deleted_at, :datetime
  end
end
