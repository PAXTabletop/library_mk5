class Group < ActiveRecord::Base

  has_many :loans

  def checked_out_games
    self.loans.where(loans: { closed: false })
  end

  def self.active
    where(deleted: false)
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

end
