class CheckoutsController < ApplicationController

  def index
    if Event.current.setup_complete?
      @checkouts = Checkout.all
    else
      @current_event = Event.current
      render '/events/_setup'
    end
  end

  def new
    checkout = Checkout.new_checkout(params.permit(:a_barcode, :g_barcode))

    if checkout.errors.messages.blank?
      render json: {
          approval: checkout.approval_tag,
          game: checkout.game.name
        }
    else
      render json: {
          errors: checkout.errors.messages
        }
    end
  end

  def return
    if params[:barcode]
      game = Game.get(params[:barcode])
      if !game
        render json: { errors: ['Game not found!'] }
        return
      end
      checkout = game.open_checkout
      if checkout
        checkout.return
        render json: { time: ct(checkout.return_time).strftime('%m/%d %I:%M%P'), game: game.name }
      else
        render json: { game: game.name }
      end
    elsif params[:co_id]
      checkout = Checkout.find(params[:co_id])
      checkout.return

      render json: { time: ct(checkout.return_time).strftime('%m/%d %I:%M%P'), game: checkout.game.name }
    end
  end

  def find
    if params[:barcode]
      # check for games
      game = Game.get(params[:barcode])
      # check attendees
      attendee = Attendee.where(
        "(barcode = ? or lower(last_name) like ?) and event_id = ?",
        params[:barcode].upcase,
        "%#{params[:barcode].downcase}%",
        @current_event
      ).order(id: :desc).first
      # if both exist, set attendee to nil
      @object = game || attendee
      # return latest checkouts for game/attendee
      @checkouts = @object ? @object.checkouts.where(event: Event.current).order(id: :desc).limit(5) : []
    end
  end

  def recent
    @recent = Checkout.recent
  end

  def longest
    @longest = Checkout.longest
  end

  def csv
    render json: { csv: Checkout.current_as_csv }
  end

end
