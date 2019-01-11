class TitlesController < ApplicationController

  def edit
    @title = Title.find(params[:id]) if params[:id]
  end

  def update
    @title = Title.find(params[:id])
    @title.update(params.permit(:title, :valuable, :publisher_id))
  end

  def cancel
    @title = Title.find(params[:id])
  end

  def csv
    render json: { csv: Title.copies_as_csv }
  end

end
