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
    result = Checkout.checkout_or_return_game(params.permit(:a_barcode, :g_barcode))

    if result[:checkout].errors.messages.blank?
      render json: {
          approval: result[:checkout].approval_tag,
          checkouts: result[:checkout].attendee.open_co.order(check_out_time: :desc).map do |co|
            render_to_string('games/checked_out_template', locals: { checkout: co }, layout: false)
          end,
          message: result[:message]
        }
    else
      render json: {
          errors: result[:checkout].errors
        }
    end
  end

  def return
    checkout = Checkout.find(params[:co_id])
    checkout.return

    render json: { time: ct(checkout.return_time).strftime('%m/%d %I:%M%P') }
  end

  def ct(datetime)
    datetime - @offset.hours
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
      @checkouts = @object ? @object.checkouts.order(id: :desc).limit(5) : []
    end
  end

  def recent
    @recent = Checkout.recent
  end

  def csv
    render json: { csv: Checkout.current_as_csv }
  end

end
