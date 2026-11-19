class MaintenanceChecklistsController < ApplicationController
  before_action :set_checklist, only: %i[show edit update destroy]
  before_action :load_assets, only: %i[new create edit update]

  def index
    redirect_to report_equipment_checklists_path(kind: "mantenedor")
  end

  def show
  end

  def new
    @checklist = MaintenanceChecklist.new
  end

  def create
    @checklist = MaintenanceChecklist.new(checklist_params)
    if @checklist.save
      redirect_to @checklist, notice: "Checklist de mantenedor registrado.", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @checklist.update(checklist_params)
      redirect_to @checklist, notice: "Checklist actualizado.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @checklist.destroy!
    redirect_to report_equipment_checklists_path(kind: "mantenedor"), notice: "Checklist eliminado.", status: :see_other
  end

  private

  def load_assets
    @assets = MobileAsset.order(:code, :id)
  end

  def set_checklist
    @checklist = MaintenanceChecklist.find(params[:id])
  end

  def checklist_params
    params.expect(maintenance_checklist: [
      :mobile_asset_id, :technician, :operating_status, :hour_meter,
      *MaintenanceChecklist::QUESTIONS.keys, *MaintenanceChecklist::FLUIDS.keys
    ])
  end
end
