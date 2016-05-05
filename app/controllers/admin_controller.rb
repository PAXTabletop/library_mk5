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

  def titles
    respond_to do |format|
      format.json { render json: Title.select(:title).distinct.order(:title).map(&:title) }
    end
  end

  def publishers
    respond_to do |format|
      format.json { render json: Publisher.select(:name).distinct.order(:name).map(&:name) }
    end
  end

end
