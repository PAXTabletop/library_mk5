class CreateTournamentGames < ActiveRecord::Migration
  def change
    create_table :tournament_games do |t|
      t.text :title
      t.integer :quantity, default: 0
      t.boolean :expansion, default: false
      t.text :notes
      t.boolean :deleted, default: false

      t.timestamps
    end
  end
end
