class AddAttendeeCountToEvents < ActiveRecord::Migration
  def change
    add_column :events, :attendee_count, :integer
  end
end