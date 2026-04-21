class EnfundadosController < ApplicationController
  before_action :set_enfundado, only: %i[ show edit update destroy ]

  # GET /enfundados or /enfundados.json
  def index
    @enfundados = Enfundado.all
  end

  # GET /enfundados/1 or /enfundados/1.json
  def show
  end

  def reporte
  @desde = params[:desde].presence
  @hasta = params[:hasta].presence

  @enfundados = Enfundado.all
  @enfundados = @enfundados.where("fecha >= ?", @desde) if @desde.present?
  @enfundados = @enfundados.where("fecha <= ?", @hasta) if @hasta.present?
  @enfundados = @enfundados.order(fecha: :desc, created_at: :desc)

  @total_manual = @enfundados.sum { |e| e.total_manual_reporte }
  @total_automatica = @enfundados.sum { |e| e.total_automatica_reporte }
  @total_films_manual = @enfundados.sum { |e| e.numero_rollos_films_cambiados_manual.to_i }
  @total_films_automatica = @enfundados.sum { |e| e.numero_rollos_films_cambiados_automatica.to_i }

  @total_gramos_manual = @enfundados.sum { |e| e.gramos_consumidos_manual }
  @total_gramos_automatica = @enfundados.sum { |e| e.gramos_consumidos_automatica }
  @total_gramos_general = @enfundados.sum { |e| e.gramos_consumidos_total }
end

  # GET /enfundados/new
  def new
    @enfundado = Enfundado.new
  end

  # GET /enfundados/1/edit
  def edit
  end

  # POST /enfundados or /enfundados.json
  def create
    @enfundado = Enfundado.new(enfundado_params)

    respond_to do |format|
      if @enfundado.save
        format.html { redirect_to enfundados_path, notice: "Registro enfundado creado." }
        format.json { render :show, status: :created, location: @enfundado }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @enfundado.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /enfundados/1 or /enfundados/1.json
  def update
    respond_to do |format|
      if @enfundado.update(enfundado_params)
        format.html { redirect_to enfundados_path, notice: "Registro enfundado actualizado.", status: :see_other }
        format.json { render :show, status: :ok, location: @enfundado }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @enfundado.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /enfundados/1 or /enfundados/1.json
  def destroy
    @enfundado.destroy!

    respond_to do |format|
      format.html { redirect_to enfundados_path, notice: "Registro eliminado.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_enfundado
      @enfundado = Enfundado.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def enfundado_params
      params.expect(enfundado: [ :operador, :fecha, :turno, :numero_pallet_enfundado_manual, :numero_pallet_enfundado_automatica, :especial_plastificados_lados_manual, :especial_plastificados_lados_automatica, :especial_plastificados_completo_manual, :especial_plastificados_completo_automatica, :especial_plastificados_3_vueltas_manual, :especial_plastificados_3_vueltas_automatica, :especial_plastificado_zuncho_reforzado_manual, :especial_plastificado_zuncho_reforzado_automatica, :especial_plastificado_completo_doble_films_manual, :especial_plastificado_completo_doble_films_automatica, :especial_soluble_plastificados_completo_manual, :especial_soluble_plastificados_completo_automatica, :extra_plastificados_lados_manual, :extra_plastificados_lados_automatica, :extra_plastificados_completo_doble_films_manual, :extra_plastificados_completo_doble_films_automatica, :extra_plastificados_completo_doble_films_zuncho_manual, :extra_plastificados_completo_doble_films_zuncho_automatica, :extra_soluble_plastificados_completo_manual, :extra_soluble_plastificados_completo_automatica, :numero_rollos_films_cambiados_manual, :numero_rollos_films_cambiados_automatica ])
    end
end
