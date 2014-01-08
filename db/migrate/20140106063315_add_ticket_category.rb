class AddTicketCategory < ActiveRecord::Migration
  def up
    add_column :tickets, :category, :string, :limit =>32
    add_column :tickets, :completed_by, :integer
    remove_column :tickets, :assigned_by
  end

end

