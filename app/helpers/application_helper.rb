module ApplicationHelper

  def ct(datetime)
    datetime - @offset.hours
  end

end
