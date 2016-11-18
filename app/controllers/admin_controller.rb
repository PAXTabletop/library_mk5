class AdminController < ApplicationController

  def index
  end

  def setup
    @game = Setup.add_game(params[:barcode]) if params[:barcode]
    @message = 'Game successfully checked in!'
  end

  def teardown
    @game = Teardown.add_game(params[:barcode]) if params[:barcode]
    @message = 'Game successfully logged for storage!'
  end

  def events
    @events = Event.all.order(start_date: :desc)
  end

  def cull
    @game = Game.get(params[:barcode]) if params[:barcode]
    @message = @game.cull_game if @game
  end

  def metrics
    @event = Event.find(params[:event]) if params[:event] # && params[:event].is_a?(Integer)
  end

  def titles
    respond_to do |format|
      format.json { render json: Title.select(:title).distinct.order(:title).map(&:title) }

      @titles = Title.active.search(params[:search]).order('lower(title) asc').paginate(per_page: 10, page: params[:page])

      format.html { }
      format.js { render 'titles/titles' }
    end
  end

  def publishers
    respond_to do |format|
      format.json { render json: Publisher.select(:name).distinct.order(:name).map(&:name) }
    end
  end

end
