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
  end

  def name
    "#{self.last_name}, #{self.first_name}#{self.volunteer ? " - [#{self.handle}]" : nil }"
  end

  def full_name
    "#{self.barcode} - #{self.name}"
  end

  def info
    self.attributes.select {|k, v| %w(first_name last_name handle barcode).include? k }.merge(name: self.name)
  end

  def open_co
    checkouts.where(closed: false)
  end

end
