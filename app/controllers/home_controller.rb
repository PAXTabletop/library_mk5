class HomeController < ApplicationController

  def home_page
    if Event.current.setup_complete?
      render 'home'
    else
      @current_event = Event.current
      render '/events/_setup'
    end
  end

end