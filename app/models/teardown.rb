class Teardown < ActiveRecord::Base
  belongs_to :game
  belongs_to :event

  def self.add_game(barcode)
    game = Game.get(barcode)
    self.find_or_create_by(game: game, event: Event.current) if game

    game
  end

end
