class AddAssignedToToTicket < ActiveRecord::Migration
  def change
    add_column :tickets, :assigned_to, :integer
    add_column :tickets, :assigned_by, :integer
  end
end
