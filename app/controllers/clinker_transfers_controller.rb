class ClinkerTransfersController < ApplicationController
  helper EnvasadoraDashboardHelper
  before_action :set_transfer, only: [ :edit, :update ]

  def index
    @dashboard = ClinkerDashboard.new(params[:period])
  end

  def new
    @transfer = ClinkerTransfer.new(date: Date.current)
  end

  def create
    @transfer = ClinkerTransfer.new(transfer_params)
    @transfer.author_email = current_user[:email]
    if @transfer.save
      redirect_to clinker_transfers_path, notice: "Traslado de clínker PTM guardado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    render :new
  end

  def update
    if @transfer.update(transfer_params)
      redirect_to clinker_transfers_path(period: "all"), notice: "Traslado de clínker PTM actualizado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_transfer
    @transfer = ClinkerTransfer.find(params[:id])
    unless task_admin? || @transfer.author_email == current_user[:email]
      redirect_to clinker_transfers_path, alert: "Solo el autor o un administrador puede editar el registro."
    end
  end

  def transfer_params
    params.require(:clinker_transfer).permit(:date, :tons, :observations)
  end
end
