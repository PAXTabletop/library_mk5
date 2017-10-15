class Group < ActiveRecord::Base

  has_many :loans

  def checked_out_games
    self.loans.where(loans: { closed: false })
  end

  def self.active
    where(deleted: false)
  end

  def active_loans
    self.loans.where(closed: false)
  end

  def soft_delete
    message = nil
    if checked_out_games.size <= 0
      self.update(deleted: true)
    else
      message = "Can not delete #{name}. #{checked_out_games.size} games still loaned to group!"
    end

    message
  end

  def loan_or_return_game(game_id)
    game = Game.find_by_barcode(game_id)
    unless game
      return {
        error: true,
        message: 'Game does not exist!'
      }
    end

    if game.checked_out?
      return {
        error: true,
        message: 'Game is currently checked out by an attendee and can not be loaned!'
      }
    end

    if game.loaned?
      if game.current_loan.group.id == self.id
        game.current_loan.update!(closed: true, return_time: Time.now)
        return {
          error: false,
          message: "Game successfully returned from #{self.name}!"
        }
      else
        return {
          error: true,
          message: "Game is already loaned to another group: '#{game.current_loan.group.name}'!"
        }
      end
    end

    Loan.create(game: game, group: self, event: Event.current, check_out_time: Time.now)

    {
      error: false,
      message: "Game successfully loaned to #{self.name}!"
    }
  end

end
