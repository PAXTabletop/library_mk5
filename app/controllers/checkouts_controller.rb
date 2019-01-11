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
      game = Game.get(params[:barcode], [Game::STATUS[:active], Game::STATUS[:stored]])
      if !game
        render json: { errors: ['Game not found!'] }
        return
      elsif game.status == Game::STATUS[:stored]
        render json: { errors: ["#{game.name} is currently in storage. Please remove it via the <a href='/admin/storage'>storage page</a> first."]}
        return
      end
      checkout = game.open_checkout
      loan = game.current_loan
      if checkout
        checkout.return
        render json: { time: ct(checkout.return_time).strftime('%m/%d %I:%M%P'), game: game.name }
      elsif loan
        render json: { errors: ["#{game.name} is currently loaned out to the group '#{loan.group.name}'. Please return it via the group's <a href='/loaners/group/#{loan.group.id}'>Loaners page</a> tab first."]}
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

  def ct(datetime)
    @_ct_current_event ||= Event.current
    datetime + @_ct_current_event.utc_offset.hours
  end

end
