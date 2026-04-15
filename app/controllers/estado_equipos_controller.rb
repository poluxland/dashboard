class EstadoEquiposController < ApplicationController
  before_action :set_estado_equipo, only: %i[ show edit update destroy ]

  # GET /estado_equipos or /estado_equipos.json
def index
  subquery = EstadoEquipo
    .where.not(equipo: [nil, ""])
    .select("MAX(id) AS id")
    .group(:equipo)

  @estado_equipos = EstadoEquipo.where(id: subquery).order(created_at: :desc)
end

  # GET /estado_equipos/1 or /estado_equipos/1.json
  def show
  end

  # GET /estado_equipos/new
  def new
    @estado_equipo = EstadoEquipo.new
  end

  # GET /estado_equipos/1/edit
  def edit
  end

  # POST /estado_equipos or /estado_equipos.json
  def create
    @estado_equipo = EstadoEquipo.new(estado_equipo_params)

    respond_to do |format|
      if @estado_equipo.save
        format.html { redirect_to @estado_equipo, notice: "Estado equipo was successfully created." }
        format.json { render :show, status: :created, location: @estado_equipo }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @estado_equipo.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /estado_equipos/1 or /estado_equipos/1.json
  def update
    respond_to do |format|
      if @estado_equipo.update(estado_equipo_params)
        format.html { redirect_to @estado_equipo, notice: "Estado equipo was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @estado_equipo }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @estado_equipo.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /estado_equipos/1 or /estado_equipos/1.json
  def destroy
    @estado_equipo.destroy!

    respond_to do |format|
      format.html { redirect_to estado_equipos_path, notice: "Estado equipo was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_estado_equipo
      @estado_equipo = EstadoEquipo.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def estado_equipo_params
      params.expect(estado_equipo: [
        :equipo_principal,
        :equipo,
        :estado_cinta,
        :estado_motor,
        :estado_polines,
        :estado_ruedas,
        :estado_capachos,
        :estado_sistema_aire,
        :estado_filtro,
        :estado_estructura,
        :estado_lubricacion,
        :estado_limpieza,
        :comentarios,
        fotos: []
      ])
    end
end
