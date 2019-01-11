class Group < ActiveRecord::Base

  has_many :loans

  def self.active
    where(deleted: false)
  end

  def active_loans
    loans.current.active.by_check_out_time
  end

  def soft_delete
    message = nil
    if active_loans.size <= 0
      self.update(deleted: true)
    else
      message = "Can not delete #{name}. #{pluralize(active_loans.size, game)} still loaned to group!"
    end

    message
  end

  def loan_or_return_game(game_barcode)
    game = Game.get(game_barcode, [Game::STATUS[:active], Game::STATUS[:stored]])
    unless game
      return {
        error: true,
        message: 'Game does not exist!'
      }
    end

    if game.checked_out?
      return {
        error: true,
        message: "#{game.name} is currently checked out by an attendee and can not be loaned!"
      }
    elsif game.status == Game::STATUS[:stored]
      return {
        error: true,
        message: "#{game.name} is currently in storage. Please remove it via the <a href='/admin/storage'>storage page</a> first."
      }
    end

    if game.loaned?
      if game.current_loan.group.id == self.id
        game.current_loan.update!(closed: true, return_time: Time.now)
        return {
          error: false,
          message: "#{game.name} successfully returned from #{self.name}!",
          removed: true
        }
      else
        return {
          error: true,
          message: "#{game.name} is already loaned to another group: <a href='/loaners/group/#{game.current_loan.group.id}'>#{game.current_loan.group.name}</a>!"
        }
      end
    end

    Loan.create(game: game, group: self, event: Event.current, check_out_time: Time.now)

    {
      error: false,
      message: "#{game.name} successfully loaned to #{self.name}!"
    }
  end

  def self.deleted
    where(deleted: true)
  end

end
