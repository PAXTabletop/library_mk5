class HomeController < ApplicationController

  def home_page
    if Event.current.setup_complete?
      render 'home'
    else
      @current_event = Event.current
      render '/events/_setup'
    end
  end

  def tutorial
    @searchText = nil
    @games = Game.search(nil, false, false, false, nil)
                 .joins(:title)
                 .order('lower(titles.title), games.barcode')
                 .paginate(per_page: 10, page: params[:page])
  end

end