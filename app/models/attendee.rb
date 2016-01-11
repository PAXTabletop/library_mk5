class Attendee < ActiveRecord::Base

  include Utilities

  has_many :checkouts

  belongs_to :event

  before_create :format_member_variables

  validates_format_of :barcode, with: Utilities.BARCODE_FORMAT
  validates :first_name, presence: true
  validates :last_name, presence: true

  def self.get(barcode)
    # search for attendee based on barcode and event
    where(barcode: barcode.upcase, event: Event.current).first
  end

  def format_member_variables
    self.barcode.upcase!
    self.volunteer = true unless self.handle.blank?
    self.event = Event.current
    self.first_name = Utilities.capitalize self.first_name
    self.last_name = Utilities.capitalize self.last_name
    self.id_state = self.id_state.upcase if self.id_state.size == 2
  end

  def name
    str = "#{self.last_name}, #{self.first_name}"
    str += " - [#{self.handle}]" if self.volunteer
    str += " from #{self.id_state}" if self.id_state

    str
  end

  def full_name
    "#{self.barcode} - #{self.name}"
  end

  def info
    self.attributes.select do |k, v|
      %w(first_name last_name handle barcode id_state).include? k
    end.merge(name: self.name)
  end

  def open_co
    checkouts.where(closed: false)
  end

end
