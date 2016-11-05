class Event < ActiveRecord::Base

  has_many :attendees
  has_many :checkouts

  def self.current
    self.all.order(start_date: :desc).first
  end

  def is_current
    self == Event.current
  end

  def short_name
    case self.name
      when /prime/i
        'west'
      when /west/i
        'west'
      when /east/i
        'east'
      when /south/i
        'south'
      when /aus/i
        'aus'
      when /dev/i
        'dev'
    end
  end

  def formatted_name
    "PAX #{self.short_name.capitalize} #{self.start_date.strftime('%Y')}"
  end

  def self.is_live
    current = self.current
    (current.start_date..current.end_date) === Date.today
  end

end
