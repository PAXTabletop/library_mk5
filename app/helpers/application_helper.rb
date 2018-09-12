module ApplicationHelper

  def ct(datetime)
    datetime + Event.current.utc_offset.hours
  end

end
