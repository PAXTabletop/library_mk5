class Teardown < ActiveRecord::Base
  belongs_to :game
  belongs_to :event

  def self.add_game(barcode)
    game = Game.get(barcode, [Game::STATUS[:active], Game::STATUS[:stored]])
    if game
    	if game.status == Game::STATUS[:stored]
    		game.toggle_storage_status
    	end
    	self.find_or_create_by(game: game, event: Event.current)
    end

    game
  end

end
