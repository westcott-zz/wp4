class AddTicketBucket < ActiveRecord::Migration
  def change
    add_column :tickets, :bucket, :string, :limit =>32
  end
end
