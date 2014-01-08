class AddUserIdToTicket < ActiveRecord::Migration
  def change
    add_column :tickets, :user_id, :integer, references: :users
    add_index :tickets, :user_id
    add_column :tickets, :contact_id, :integer, references: :contacts
    add_index :tickets, :contact_id
  end
end
