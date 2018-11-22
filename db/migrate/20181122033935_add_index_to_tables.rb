class AddIndexToTables < ActiveRecord::Migration
  def change
  	# Attendees
    add_index :attendees, :barcode
    add_index :attendees, :event_id

    # Checkouts
    add_index :checkouts, :game_id
    add_index :checkouts, :attendee_id
    add_index :checkouts, :event_id

    # Events
    add_index :events, :start_date, order: :desc

    # Games
    add_index :games, :barcode
    add_index :games, :title_id

    # Loans
    add_index :loans, :game_id
    add_index :loans, :group_id

    # Setups
    add_index :setups, :game_id
    add_index :setups, :event_id

    # Suggestions
    add_index :suggestions, :event_id

    # Teardowns
    add_index :teardowns, :game_id
    add_index :teardowns, :event_id

    # Titles
    add_index :titles, :publisher_id
  end
end
