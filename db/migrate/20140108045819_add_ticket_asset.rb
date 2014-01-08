class AddTicketAsset < ActiveRecord::Migration
  def up
    add_column :tickets, :asset_type, :string
    add_column :tickets, :asset_id, :integer
  end

  def down
  end
end
