class AttendeesController < ApplicationController

  def status
    attendee = Attendee.get(params[:barcode])
    if attendee
      render json: {
          attendee: attendee.info,
          checkouts: attendee.open_co.order(check_out_time: :desc).map do |co|
            render_to_string('games/checked_out_template', locals: { checkout: co }, layout: false)
          end
        }
    else
      render json: nil, status: 400
    end
  end

  def new
    attendee = Attendee.create(params.permit(:barcode, :first_name, :last_name, :handle, :id_state))

    if attendee.errors && !attendee.errors.messages.blank?
      render json: {
          errors: attendee.errors.messages
        }
    else
      render json: {
          attendee: attendee.info
        }
    end
  end

end
