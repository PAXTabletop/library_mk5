class GamesController < ApplicationController

  def index
    @searchTitle = nil || params[:title]
    @searchPublisher = nil || params[:publisher]
    @searchValuable = nil || params[:valuable].present?
    @searchChecked = nil || params[:checked].present?
    @searchLoaned = nil || params[:loaned].present?
    @searchGroup = nil || params[:group]
    @games = Game.search(@searchTitle, @searchPublisher, @searchValuable, @searchChecked, @searchLoaned, @searchGroup).joins(:title).order('lower(titles.title), games.barcode').paginate(per_page: 10, page: params[:page])
  end

  def status
    game = Game.get(params[:barcode], [Game::STATUS[:active], Game::STATUS[:stored]])
    if game
      if game.stored?
        game.toggle_storage_status
      end
      @message = 'This game already exists in the system.'
      render json: {
        game: game.info,
        message: @message
      }
    else
      render json: nil, status: 400
    end
  end

  def new
    game = Game.generate(params.permit(:barcode, :title, :publisher, :valuable))

    if game.errors && !game.errors.messages.blank?
      render json: {
          errors: game.errors.messages
        }
    else
      render json: {
          game: game.info
        }
    end
  end

  def display
    @message = params[:message]
    @game = Game.get(params[:barcode])
  end

  def csv
    render json: { csv: Game.copies_as_csv }
  end

end
