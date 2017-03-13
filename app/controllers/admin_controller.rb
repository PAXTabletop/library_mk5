class AdminController < ApplicationController

  def index
  end

  def setup
    respond_to do |format|
      format.js {
        @game = Setup.add_game(params[:barcode]) if params[:barcode]
        @message = 'Checked in game for setup:'
        @games_left = Game.remaining_from('setups')
      }
      format.html {
        @games_left = Game.remaining_from('setups')
      }
    end
  end

  def teardown
    respond_to do |format|
      format.js {
        @game = Teardown.add_game(params[:barcode]) if params[:barcode]
        @message = 'Checked in game for teardown:'
        @games_left = Game.remaining_from('teardowns')
      }
      format.html {
        @games_left = Game.remaining_from('teardowns')
      }
    end
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

  def purge
  end

  def missing
  end

  def setup_tag
    Event.current.update_setup_tag(params[:tag])
    render json: :nothing
  end

  def tournament_games
    @tournament_games = TournamentGame.active.order(title: :asc).paginate(per_page: 10, page: params[:page])
  end

  def titles
    respond_to do |format|
      format.json { render json: Title.select(:title).distinct.order(:title).map(&:title) }

      @titles = Title.active.search(params[:search]).paginate(per_page: 10, page: params[:page])

      format.html { }
      format.js { render 'titles/titles' }
    end
  end

  def publishers
    respond_to do |format|
      format.json { render json: Publisher.select(:name).distinct.order(:name).map(&:name) }

      @publishers = Publisher.active.search(params[:search]).paginate(per_page: 10, page: params[:page])

      format.html { }
      format.js { render 'publishers/publishers' }
    end
  end

  def reports
  end

  def backup
  end

end
