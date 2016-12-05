class PublishersController < ApplicationController

  def edit
    @publisher = Publisher.find(params[:id]) if params[:id]
  end

  def update
    @publisher = Publisher.find(params[:id])
    @publisher.update(params.permit(:name))
  end

  def cancel
    @publisher = Publisher.find(params[:id])
  end

end
