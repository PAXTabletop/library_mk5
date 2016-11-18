class EventsController < ApplicationController

  def create
    @event = Event.create(params.permit(:name, :location, :start_date, :end_date))
  end

  def edit
    @event = Event.find(params[:id]) if params[:id]
    @event = Event.new if @event.nil?
  end

  def update
    @event = Event.find(params[:id])
    @event.update(params.permit(:name, :location, :start_date, :end_date, :utc_offset))
  end

  def cancel
    if params[:id].blank?
      @event = Event.new
    else
      @event = Event.find(params[:id])
    end
  end

end
