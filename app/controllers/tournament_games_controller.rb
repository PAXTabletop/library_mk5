class TournamentGamesController < ApplicationController

  def create
    @tournament_game = TournamentGame.create(params.permit(:title, :quantity, :expansion, :notes))
    @tournament_games = TournamentGame.active.order(title: :asc).paginate(per_page: 10, page: params[:page])
  end

  def edit
    @tournament_game = TournamentGame.find(params[:id]) if params[:id]
    @tournament_game = TournamentGame.new if @tournament_game.nil?
  end

  def update
    @tournament_game = TournamentGame.find(params[:id])
    @tournament_game.update(params.permit(:title, :quantity, :expansion, :notes))
  end

  def cancel
    @tournament_game = TournamentGame.find(params[:id]) unless params[:id].empty?
    @tournament_game = TournamentGame.new if @tournament_game.nil?
  end

  def delete
    @tournament_game_id = params[:id]
    TournamentGame.find(params[:id]).update(deleted: true)

    @tournament_games = TournamentGame.active.order(title: :asc).paginate(per_page: 10, page: params[:page])
  end

  def recently_deleted
    @tournament_games = TournamentGame.where(deleted: true).order(updated_at: :desc).limit(5)
  end

  def restore
    @tournament_game = TournamentGame.find(params[:id])
    @tournament_game.update(deleted: false)
  end

end
