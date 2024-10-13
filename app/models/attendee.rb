class Attendee < ActiveRecord::Base

  include Utilities

  has_many :checkouts

  belongs_to :event

  before_create :format_member_variables

  validates_format_of :barcode, with: Utilities.BARCODE_FORMAT

  def self.get(barcode)
    # search for attendee based on barcode and event
    where(barcode: barcode.upcase, event: Event.current).first
  end

  def format_member_variables
    self.barcode.upcase!
    self.event = Event.current
  end

  def name
    "#{self.barcode}"
  end

  def full_name
    "#{self.barcode}"
  end

  def info
    self.attributes.select do |k, v|
      %w(barcode).include? k
    end
  end

  def open_co
    checkouts.where(closed: false)
  end

end
