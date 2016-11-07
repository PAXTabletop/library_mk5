class Checkout < ActiveRecord::Base

  belongs_to :game
  belongs_to :attendee
  belongs_to :event

  before_create :fill_in_fields

  validates :attendee, presence: true
  validates :game, presence: true
  validates_each :game, on: :create do |record, attr, value|
    if value
      record.errors.add(attr, 'Game is already checked out.') unless value.checked_in?
      record.errors.add(attr, 'Game does not exist.') if value.culled
    end
  end

  def self.longest_checkout_time_today(offset)
    minimum_time = self.where(closed: false).where("(check_out_time - '#{offset} hours'::interval)::date = ?", Date.today.to_s).minimum(:check_out_time).to_i

    difference = minimum_time == 0 ? 0 : Time.now - minimum_time

    Time.at(difference).utc.strftime('%H:%M:%S')
  end

  def fill_in_fields
    self.event = Event.current
    self.check_out_time = Time.now.utc
  end

  def self.new_checkout(params)
    Checkout.create(game: Game.get(params[:g_barcode]), attendee: Attendee.get(params[:a_barcode]))
  end

  def return
    self.return_time = Time.now.utc
    self.closed = true
    self.save
  end

  def self.recent
    self.where(event: Event.current).order(updated_at: :desc).limit(5)
  end

end
