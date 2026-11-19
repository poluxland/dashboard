class MobileAssetsController < ApplicationController
  before_action :set_asset, only: %i[show edit update destroy]

  def index
    @assets = MobileAsset.order(:code, :id)
  end

  def show
    @checklists = EquipmentInspectionReport.new(asset_id: @asset.id).rows.order(created_at: :desc, kind: :asc, id: :desc).limit(10)
  end

  def new
    @asset = MobileAsset.new
  end

  def create
    @asset = MobileAsset.new(asset_params)
    if @asset.save
      redirect_to @asset, notice: "Equipo creado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @asset.update(asset_params)
      redirect_to @asset, notice: "Equipo actualizado.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @asset.checklist_history.exists? || @asset.checklist_history(MaintenanceChecklist).exists? || !@asset.destroy
      redirect_to @asset, alert: "Este equipo tiene checklists y no se puede eliminar.", status: :see_other
    else
      redirect_to mobile_assets_path, notice: "Equipo eliminado.", status: :see_other
    end
  end

  private

  def set_asset
    @asset = MobileAsset.find(params[:id])
  end

  def asset_params
    params.expect(mobile_asset: %i[code brand model plant year notes])
  end
end
