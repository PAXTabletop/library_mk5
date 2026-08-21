class CheckoutsController < ApplicationController

  def checkout_page
    if Event.current.setup_complete?
      render 'checkout'
    else
      @current_event = Event.current
      render '/events/_setup'
    end
  end

  def new
    if params[:a_barcode]
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
      return
    end

    game = Game.get(params[:g_barcode], [Game::STATUS[:active], Game::STATUS[:stored]])
    if !game
      render json: { errors: ['Game not found!'] }
    elsif game.status == Game::STATUS[:stored]
      game.toggle_storage_status
      render json: { game: game.name, storage_removed: game.active? }
    else
      checkout = game.open_checkout
      checkout.return if checkout
      loan = game.current_loan
      loan.update!(closed: true, return_time: Time.now.utc) if loan
      render json: { game: game.name, cleared: !!(checkout || loan) }
    end
  end

  def return_page
    if Event.current.setup_complete?
      render 'return'
    else
      @current_event = Event.current
      render '/events/_setup'
    end
  end

  def return
    if params[:barcode]
      game = Game.get(params[:barcode], [Game::STATUS[:active], Game::STATUS[:stored]])
      if !game
        render json: { errors: ['Game not found!'] }
        return
      elsif game.status == Game::STATUS[:stored]
        game.toggle_storage_status
        render json: { game: game.name, storage_removed: game.active? }
        return
      end
      checkout = game.open_checkout
      loan = game.current_loan
      if checkout
        checkout.return
        render json: { time: ct(checkout.return_time).strftime('%m/%d %I:%M%P'), game: game.name }
      elsif loan
        loan.update!(closed: true, return_time: Time.now.utc)
        render json: { time: ct(loan.return_time).strftime('%m/%d %I:%M%P'), game: game.name }
      else
        render json: { game: game.name }
      end
    elsif params[:co_id]
      checkout = Checkout.find(params[:co_id])
      checkout.return

      render json: { time: ct(checkout.return_time).strftime('%m/%d %I:%M%P'), game: checkout.game.name }
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
