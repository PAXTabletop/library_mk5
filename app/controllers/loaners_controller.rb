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

  def group_index
    @group = Group.find(params[:id])
    @loans_by_title_id = @group.active_loans.joins(game: :title).select('loans.id AS id', 'loans.check_out_time AS check_out_time', 'games.barcode AS barcode', 'games.title_id AS title_id', 'titles.title AS name').group_by{ |loan| loan.title_id }

    if order = params[:order]
      order = order.split(',').map(&:to_i)
      new_keys = @loans_by_title_id.keys - order
      new_keys += order
      @loans_by_title_id = new_keys.each_with_object({}) do |key, obj|
        temp = @loans_by_title_id[key]
        if temp
          obj[key] = temp
        end
      end
    end
  end

  def new
    @group = Group.find(params[:group_id])
    result = @group.loan_or_return_game(params[:game_barcode])

    render json: {
        error: result[:error],
        message: result[:message],
        removed: result[:removed]
      }
  end

  def groups_deleted
    @groups = Group.deleted
  end

  def restore
    @group = Group.find(params[:id])
    @group.update!(deleted: false)
  end

end
