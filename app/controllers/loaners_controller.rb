class LoanersController < ApplicationController

  def index
    @groups = Group.active.order(created_at: :desc)
  end

  def create
    @group = Group.create(params.permit(:name, :description))
  end

  def edit
    @group = Group.find(params[:id]) if params[:id]
    @group = Group.new if @group.nil?
  end

  def update
    @group = Group.find(params[:id])
    @group.update(params.permit(:name, :description))
  end

  def cancel
    if params[:id].blank?
      @group = Group.new
    else
      @group = Group.find(params[:id])
    end
  end

  def delete
    @group_id = params[:id]
    @group = Group.find(@group_id)
    @message = @group.soft_delete

    @groups = Group.active.order(created_at: :desc)
  end

end
