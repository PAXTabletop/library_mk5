class Loan < ActiveRecord::Base

  belongs_to :group
  belongs_to :game
  belongs_to :event

  validates_each :game, on: :create do |record, attr, value|
    if value
      record.errors.add(attr, "#{game.name} is already checked out to an attendee.") unless value.checked_in?
      record.errors.add(attr, 'Game does not exist.') if value.culled?
    end
  end

  scope :active, -> { where(closed: false).joins(:game).where('games.status = ?', Game::STATUS[:active]) }
  scope :current, -> { where(event: Event.current) }
  scope :by_check_out_time, ->(direction=:desc) { order(check_out_time: direction) }
end
