class CreateLoansAndGroups < ActiveRecord::Migration
  def change
    create_table :loans do |t|
      t.integer :game_id
      t.integer :group_id
      t.timestamp :check_out_time
      t.timestamp :return_time
      t.boolean :closed, default: false
      t.integer :event_id

      t.timestamps
    end

    create_table :groups do |t|
      t.text :name
      t.text :description
      t.boolean :deleted, default: false

      t.timestamps
    end
  end
end
