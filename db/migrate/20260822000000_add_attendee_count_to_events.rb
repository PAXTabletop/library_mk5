class AddAttendeeCountToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :events, :attendee_count, :integer
  end
end