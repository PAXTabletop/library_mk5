class AddUtcOffsetToEvents < ActiveRecord::Migration
  def change
    add_column :events, :utc_offset, :integer, default: 0
  end
end
