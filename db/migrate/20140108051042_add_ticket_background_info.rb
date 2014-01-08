class AddTicketBackgroundInfo < ActiveRecord::Migration
  def up
    add_column :tickets, :background_info, :string
    add_column :tickets, :subscribed_users, :text
  end
end
