class PmmCatalogsController < ApplicationController
  CATALOGS = {
    "materias" => {
      model: PmmMaterial, title: "Materias primas",
      fields: { nombre: "Nombre", descripcion: "Descripción", densidad: "Densidad" }
    },
    "canchas" => {
      model: PmmYard, title: "Canchas",
      fields: { nombre: "Nombre", descripcion: "Descripción", capacidad: "Capacidad",
                operativa: "Operativa", pmm_material_id: "Materia prima" }
    }
  }.freeze

  before_action :set_catalog
  before_action :set_record, only: %i[edit update destroy]
  before_action :load_materials, only: %i[new edit create update]

  def index
    @records = @catalog[:model].order(:nombre)
    @records = @records.includes(:pmm_material) if @kind == "canchas"
  end

  def new
    @record = @catalog[:model].new
  end

  def create
    @record = @catalog[:model].new(record_params)
    if @record.save
      redirect_to pmm_catalog_path(@kind), notice: "Registro creado.", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @record.update(record_params)
      redirect_to pmm_catalog_path(@kind), notice: "Registro actualizado.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    return head :forbidden unless task_admin?

    if @record.destroy
      redirect_to pmm_catalog_path(@kind), notice: "Registro eliminado.", status: :see_other
    else
      redirect_to pmm_catalog_path(@kind), alert: "Esta materia prima tiene camiones o canchas asociados.", status: :see_other
    end
  end

  private

  def set_catalog
    @kind = params.expect(:kind)
    @catalog = CATALOGS[@kind]
    head :not_found unless @catalog
  end

  def load_materials
    @materials = PmmMaterial.order(:nombre) if @kind == "canchas"
  end

  def set_record
    @record = @catalog[:model].find(params.expect(:id))
  end

  def record_params
    params.expect(record: @catalog[:fields].keys)
  end
end
