class AddLicenseStateToAttendee < ActiveRecord::Migration
  def change
    add_column :attendees, :id_state, :string, limit: 30
  end
end
