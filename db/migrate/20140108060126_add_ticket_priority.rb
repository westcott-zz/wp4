class AddTicketPriority < ActiveRecord::Migration
  def up
    add_column :tickets, :priority, :string, :limit => 32
  end
end
