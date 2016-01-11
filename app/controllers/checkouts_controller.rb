class CheckoutsController < ApplicationController

  def index
    @checkouts = Checkout.all
  end

  def new
    checkout = Checkout.new_checkout(params.permit(:a_barcode, :g_barcode))

    if checkout.errors.messages.blank?
      render json: {
          checkouts: checkout.attendee.open_co.order(check_out_time: :desc).map do |co|
            render_to_string('games/checked_out_template', locals: { checkout: co }, layout: false)
          end
        }
    else
      render json: {
          errors: checkout.errors.messages
        }
    end
  end

  def return
    Checkout.find(params[:co_id]).return

    render json: :nothing
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

end
