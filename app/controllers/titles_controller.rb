class TitlesController < ApplicationController

  def edit
    @title = Title.find(params[:id]) if params[:id]
  end

  def update
    @title = Title.find(params[:id])
    @title.update(params.permit(:title, :likely_tournament))
  end

  def cancel
    @title = Title.find(params[:id])
  end

end
