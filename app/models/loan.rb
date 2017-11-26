class Loan < ActiveRecord::Base

  belongs_to :group
  belongs_to :game
  belongs_to :event

  validates_each :game, on: :create do |record, attr, value|
    if value
      record.errors.add(attr, 'Game is already checked out to an attendee.') unless value.checked_in?
      record.errors.add(attr, 'Game does not exist.') if value.culled?
    end
  end

  scope :active, -> { where(closed: false) }
  scope :current, -> { where(event: Event.current) }
  scope :by_check_out_time, -> (direction = :desc) { order(check_out_time: direction) }
end
