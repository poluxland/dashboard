class EquipmentChecklistsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[new create]
  before_action :set_checklist, only: %i[show edit update destroy]
  before_action :load_assets, only: %i[new create edit update index report]

  def index
    respond_to do |format|
      format.html { @pagy, @checklists = pagy(filtered_checklists, limit: 30) }
      format.xlsx do
        @checklists = filtered_checklists
        response.headers["Content-Disposition"] = 'attachment; filename="checklists-equipos.xlsx"'
      end
    end
  end

  def report
    @filters = params.permit(:kind, :asset_id, :plant, :from, :to, :status, :observations).to_h
    report = EquipmentInspectionReport.new(@filters)
    scope = report.rows

    respond_to do |format|
      format.html do
        @plant_options = report.plant_options
        @groups = scope.group(:report_plant, :kind, :report_status).count
        @pagy, @checklists = pagy(scope.order(created_at: :desc, kind: :asc, id: :desc), limit: 30)
      end
      format.csv do
        send_data report.csv(scope), filename: "informe-checklists-equipos.csv", type: "text/csv; charset=utf-8"
      end
    end
  end

  def show
  end

  def new
    asset = @assets.find { |item| item.id.to_s == params[:asset_id] }
    @checklist = EquipmentChecklist.new(mobile_asset: asset)
    @checklist.c17 = EquipmentChecklist.plant_code(asset&.plant) if signed_in?
  end

  def create
    @checklist = EquipmentChecklist.new(checklist_params)
    if @checklist.save
      destination = signed_in? ? @checklist : new_equipment_checklist_path
      redirect_to destination, notice: "Checklist registrado.", status: :see_other
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
    redirect_to equipment_checklists_path, notice: "Checklist eliminado.", status: :see_other
  end

  private

  def load_assets
    assets = MobileAsset.order(:code, :id)
    assets = assets.select(:id, :code) unless signed_in?
    @assets = assets.to_a
  end

  def set_checklist
    @checklist = EquipmentChecklist.find(params[:id])
  end

  def filtered_checklists
    @filters = params.permit(:asset_id, :plant, :from, :to, :status, :observations).to_h
    @plant_options = EquipmentChecklist::PLANTS.keys
    scope = EquipmentChecklist.all
    if @filters[:asset_id].present?
      asset = @assets.find { |item| item.id.to_s == @filters[:asset_id] }
      scope = asset ? asset.checklist_history : scope.none
    end
    scope = scope.where(c17: @filters[:plant]) if @filters[:plant].present?
    if EquipmentChecklist::STATUSES.key?(@filters[:status])
      scope = scope.where("(#{EquipmentChecklist::STATUS_SQL}) = ?", @filters[:status])
    end
    if @filters[:observations] == "1"
      scope = scope.where("(#{EquipmentChecklist::STATUS_SQL}) IN ('grave', 'leve') OR NULLIF(BTRIM(comments), '') IS NOT NULL")
    end

    from = local_midnight(@filters[:from])
    to = local_midnight(@filters[:to], next_day: true)
    scope = scope.where(created_at: from..) if from
    scope = scope.where(created_at: ...to) if to
    scope.includes(:mobile_asset).order(created_at: :desc, id: :desc)
  end

  def local_midnight(value, next_day: false)
    return if value.blank?

    date = Date.iso8601(value)
    date += 1 if next_day
    Time.find_zone!("America/Santiago").local(date.year, date.month, date.day)
  rescue Date::Error, ArgumentError
    nil
  end

  def checklist_params
    params.expect(equipment_checklist: [ :mobile_asset_id, :operator, :hour_meter, :c17, :comments, *EquipmentChecklist::QUESTIONS.keys ])
  end
end
