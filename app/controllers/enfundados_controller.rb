class EnfundadosController < ApplicationController
  STOCK_FISICO_FILMS = 2
  FECHA_STOCK_FISICO_FILMS = Date.new(2026, 8, 23)

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

  # Totales que se muestran en la tabla
  @total_manual = @enfundados.sum { |e| e.total_manual_reporte.to_i }
  @total_automatica = @enfundados.sum { |e| e.total_automatica_reporte.to_i }

  # Films cambiados según registros de enfundado
  @total_films_manual = @enfundados.sum(&:films_usados_manual)
  @total_films_automatica = @enfundados.sum(&:films_usados_automatica)
  @total_films_tapa = @enfundados.sum(&:films_usados_tapa)
  @total_films_usados = @total_films_manual + @total_films_automatica + @total_films_tapa

  # Gramos consumidos
  @total_gramos_manual = @enfundados.sum { |e| e.gramos_consumidos_manual.to_i }
  @total_gramos_automatica = @enfundados.sum { |e| e.gramos_consumidos_automatica.to_i }
  @total_gramos_general = @enfundados.sum { |e| e.gramos_consumidos_total.to_i }

  # Rollos entregados por bodega
  @entregas_films = EntregaFilm.all
  @entregas_films = @entregas_films.where("fecha >= ?", @desde) if @desde.present?
  @entregas_films = @entregas_films.where("fecha <= ?", @hasta) if @hasta.present?

  @total_films_entregados = @entregas_films.sum(:rollos_entregados).to_i

  # Diferencia entre rollos entregados y films registrados como usados
  @diferencia_films = @total_films_entregados - @total_films_usados

  # Cálculo estimado de rollos según gramos
  @rollos_usados_segun_gramos = @total_gramos_general.to_f / 15000
  @diferencia_rollos_segun_gramos = @total_films_entregados.to_f - @rollos_usados_segun_gramos

  # Pallet enfundados: usa los mismos métodos que la tabla
  @total_pallet_manual = @enfundados.sum { |e| e.total_manual_reporte.to_i }
  @total_pallet_automatica = @enfundados.sum { |e| e.total_automatica_reporte.to_i }
  @total_pallet_enfundados = @total_pallet_manual + @total_pallet_automatica

  # Clasificación EP pallet enfundado
  @total_pallet_enf_normal = @enfundados.sum { |e| e.pallet_enf_normal.to_i }
  @total_pallet_enf_completo = @enfundados.sum { |e| e.pallet_enf_completo.to_i }
  @total_pallet_enf_zuncho = @enfundados.sum { |e| e.pallet_enf_zuncho.to_i }

  @total_pallet_enf_calculado =
    @total_pallet_enf_normal +
    @total_pallet_enf_completo +
    @total_pallet_enf_zuncho

end

  def inventario_films
    cargar_inventario_films
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
      params.expect(enfundado: [ :operador, :fecha, :turno, :numero_pallet_enfundado_manual, :numero_pallet_enfundado_automatica, :especial_plastificados_lados_manual, :especial_plastificados_lados_automatica, :especial_plastificados_completo_manual, :especial_plastificados_completo_automatica, :especial_plastificados_3_vueltas_manual, :especial_plastificados_3_vueltas_automatica, :especial_plastificado_zuncho_reforzado_manual, :especial_plastificado_zuncho_reforzado_automatica, :especial_plastificado_completo_doble_films_manual, :especial_plastificado_completo_doble_films_automatica, :especial_soluble_plastificados_completo_manual, :especial_soluble_plastificados_completo_automatica, :extra_plastificados_lados_manual, :extra_plastificados_lados_automatica, :extra_plastificados_completo_doble_films_manual, :extra_plastificados_completo_doble_films_automatica, :extra_plastificados_completo_doble_films_zuncho_manual, :extra_plastificados_completo_doble_films_zuncho_automatica, :extra_soluble_plastificados_completo_manual, :extra_soluble_plastificados_completo_automatica, :numero_rollos_films_cambiados_manual, :numero_rollos_films_cambiados_automatica, :numero_rollos_films_tapa ])
    end

    def cargar_inventario_films
      @inventario_hasta = Date.current
      @inventario_desde = @inventario_hasta - 14.days
      @inventario_dias = (@inventario_desde..@inventario_hasta).to_a

      entregas_hasta_conteo = EntregaFilm
        .where(fecha: ..FECHA_STOCK_FISICO_FILMS)
        .sum(:rollos_entregados)
        .to_i
      usados_hasta_conteo = total_rollos_films_usados(
        Enfundado.where(fecha: ..FECHA_STOCK_FISICO_FILMS)
      )
      ajuste_inventario =
        STOCK_FISICO_FILMS -
        (entregas_hasta_conteo - usados_hasta_conteo)

      entregas_anteriores = EntregaFilm.where("fecha < ?", @inventario_desde).sum(:rollos_entregados).to_i
      usados_anteriores = total_rollos_films_usados(
        Enfundado.where("fecha < ?", @inventario_desde)
      )
      @inventario_inicial = entregas_anteriores - usados_anteriores + ajuste_inventario

      @inventario_entregas_por_dia = EntregaFilm
        .where(fecha: @inventario_desde..@inventario_hasta)
        .group(:fecha)
        .sum(:rollos_entregados)

      @inventario_usados_por_dia = Enfundado
        .where(fecha: @inventario_desde..@inventario_hasta)
        .group_by(&:fecha)
        .transform_values do |registros|
          registros.sum(&:films_usados_total)
        end

      saldo_inventario = @inventario_inicial
      @inventario_por_dia = @inventario_dias.to_h do |fecha|
        saldo_inventario += @inventario_entregas_por_dia.fetch(fecha, 0).to_i
        saldo_inventario -= @inventario_usados_por_dia.fetch(fecha, 0).to_i
        [ fecha, saldo_inventario ]
      end
    end

    def total_rollos_films_usados(registros)
      registros.sum do |enfundado|
        enfundado.films_usados_total
      end
    end

end
