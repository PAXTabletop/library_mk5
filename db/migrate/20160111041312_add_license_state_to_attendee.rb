class AddLicenseStateToAttendee < ActiveRecord::Migration[4.2]
  def change
    add_column :attendees, :id_state, :string, limit: 30
  end
end
