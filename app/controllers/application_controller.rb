class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :global_val

  def app_status
    open_checkouts = Checkout.where(closed: false, event: Event.current).size
    longest_open_checkout = Checkout.longest_checkout_time_today(@offset)
    total_games = Game.active.size

    render json: {
        open_checkouts: open_checkouts,
        longest_open_checkout: longest_open_checkout,
        total_games: total_games,
        current_offset: @offset
      }
  end

  def global_val
    @current_event = Event.current unless @current_event
    @offset = request.headers[:clientOffset].to_i
  end

  def suggest_a_title
    title = Suggestion.add_suggestion(params.permit(:title)[:title])

    render json: { title: title }
  end

end
