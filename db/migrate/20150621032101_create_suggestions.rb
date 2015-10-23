class CreateSuggestions < ActiveRecord::Migration
  def change
    create_table :suggestions do |t|
      t.text :title
      t.integer :votes, default: 0
      t.integer :event_id

      t.timestamps
    end
  end
end
