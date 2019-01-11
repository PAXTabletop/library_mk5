include ActionView::Helpers::NumberHelper

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
    @game = Game.get(params[:barcode], [Game::STATUS[:active], Game::STATUS[:stored]]) if params[:barcode]
    if @game
      if !params[:approve] && @game.valuable?
        @valuable = true
      else
        @message = @game.cull_game
      end
    end
  end

  def metrics
    @event = Event.find(params[:event]) if params[:event] # && params[:event].is_a?(Integer)
  end

  def suggestions
    @event = Event.find(params[:event]) if params[:event] # && params[:event].is_a?(Integer)
  end

  def purge
  end

  def missing
  end

  def storage
    @storage_by_title_id = Game.stored.select(:title_id, :barcode).includes(:title).group_by{ |game| game.title_id }
  end

  def store_game
    @game = Game.get(params[:game_barcode], [Game::STATUS[:active], Game::STATUS[:stored]]) if params[:game_barcode]
    result = @game.toggle_storage_status if @game

    if !result
      render json: {
        error: true,
        message: "Game does not exist."
      }
    else
      render json: {
        error: result[:error],
        message: result[:message],
        removed: result[:removed]
      }
    end
  end

  def csv
    render json: { csv: Game.storage_copies_as_csv }
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

  def added_games
    @event = Event.find(params[:event]) if params[:event]
    @games = Game.added_during_show(@event)
  end

  def culled_games
    @event = Event.find(params[:event]) if params[:event]
    @games = Game.culled_during_show(@event)
  end

  def about
  end

  def stats
    curr_event = Event.current
    games = curr_event.top_games()
    titles_count = Game.active.count
    active_checkouts_count = Checkout.for_current_event.active.count
    checked_out = number_to_percentage((active_checkouts_count.to_f / titles_count) * 100)
    titles_played_count = Checkout.for_current_event.joins(game: [:title]).group(:title).count.size
    total_checkouts_count = Checkout.for_current_event.count
    longest_checkout = Checkout.longest_checkout_game_today(curr_event.utc_offset)
    total_hours_played = Checkout.for_current_event.to_a.sum(&:hours_played) / 1.hour
    random_game = Game.random_game()

    render json: {
      current_event: curr_event.short_name,
      games: games,
      random_game: random_game,
      stats: {
        titles: titles_count,
        active_checkouts: active_checkouts_count,
        checked_out: checked_out,
        titles_played: titles_played_count,
        total_checkouts: total_checkouts_count,
        longest_checkout: longest_checkout,
        hours_played: total_hours_played,
      },
      current_offset: curr_event.utc_offset
    }
  end

end
