module ApplicationHelper

  def ct(datetime)
    @_ct_current_event ||= Event.current
    datetime + @_ct_current_event.utc_offset.hours
  end

end
