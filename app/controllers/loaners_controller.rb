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
  end

  def new
    @group = Group.find(params[:group_id])
    result = @group.loan_or_return_game(params[:game_barcode])

    render json: {
        error: result[:error],
        message: result[:message],
        loans: @group.active_loans.map do |loan|
          render_to_string('loaners/_loaned_game', locals: { loan: loan }, layout: false )
        end
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
