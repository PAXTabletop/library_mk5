class RemovePiiFromAttendees < ActiveRecord::Migration
  def change
    remove_column :attendees, :first_name, :string
    remove_column :attendees, :last_name, :string
    remove_column :attendees, :id_state, :string
    remove_column :attendees, :handle, :string
    remove_column :attendees, :volunteer, :boolean
  end
end
