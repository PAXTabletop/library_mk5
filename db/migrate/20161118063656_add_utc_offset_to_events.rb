class AddUtcOffsetToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :utc_offset, :integer, default: 0
  end
end
