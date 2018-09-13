class Setup < ActiveRecord::Base
  belongs_to :game
  belongs_to :event

  def self.add_game(barcode)
    game = Game.get(barcode, [Game::STATUS[:active], Game::STATUS[:stored]])
    if game
      if game.stored?
        game.toggle_storage_status()
      end
      self.find_or_create_by(game: game, event: Event.current)
    end
    game
  end

  def self.add_new_game(game)
    self.find_or_create_by(game: game, event: Event.current) if game
  end

end
