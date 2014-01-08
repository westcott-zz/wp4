class CreateTickets < ActiveRecord::Migration
  def change
    create_table :tickets do |t|
      t.string :title
      t.text :description
      t.string :status, :limit => 32

      t.timestamps
    end
  end
end
