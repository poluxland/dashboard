class OtsController < ApplicationController
  before_action :set_ot, only: %i[ show edit update destroy ]

  # GET /ots



  def index
    @q = params[:q].to_s.strip
    estados = Array(params[:estado]).reject(&:blank?)
    tipos   = Array(params[:tipo_ot]).reject(&:blank?)

    scope = Ot.search(@q)
    scope = scope.where(estado: estados.map(&:to_i)) if estados.any?
    scope = scope.where("LOWER(tipo_ot) IN (?)", tipos.map { |t| t.to_s.downcase }) if tipos.any?
    scope = scope.order(created_at: :desc)

    @pagy, @ots = pagy(scope, items: (params[:per]&.to_i.presence || 20))

    respond_to do |format|
      format.html
      format.xlsx do
        @ots_xlsx = scope # exporta con los filtros aplicados
        response.headers["Content-Disposition"] =
          "attachment; filename=ots_#{Time.zone.now.strftime('%Y%m%d_%H%M')}.xlsx"
      end
    end
  end









def compact
  @ots = Ot.order(created_at: :desc)
end

def backlog
  @ots = Ot.where(estado: [70, 30]).order(created_at: :desc)
end




  def graficos
    scope = Ot.all

    # --- Tipo OT (%)
    tipo_counts  = scope.group(:tipo_ot).count
    total_tipos  = tipo_counts.values.sum.nonzero? || 1
    @tipo_labels = tipo_counts.keys.map { |k| k.presence || "Sin tipo" }
    @tipo_values = tipo_counts.values.map { |v| ((v.to_f / total_tipos) * 100).round(1) }

    # --- Estado (%)
    estado_counts  = scope.group(:estado).count
    total_estados  = estado_counts.values.sum.nonzero? || 1
    @estado_labels = estado_counts.keys.map { |k| k.presence || "Sin estado" }
    @estado_values = estado_counts.values.map { |v| ((v.to_f / total_estados) * 100).round(1) }

    # --- Cumplimientos por especialidad (MM/ME/MI)
    calc_pct = ->(rel) do
      counts = rel.group(:estado).count
      labels = counts.keys.map { |k| k.presence || "Sin estado" }
      tot    = counts.values.sum.nonzero? || 1
      values = counts.values.map { |v| ((v.to_f / tot) * 100).round(1) }
      [ labels, values ]
    end
    @mm_labels, @mm_values = calc_pct.call(scope.where(esp: "MM"))
    @me_labels, @me_values = calc_pct.call(scope.where(esp: "ME"))
    @mi_labels, @mi_values = calc_pct.call(scope.where(esp: "MI"))

    # --- NUEVO: Total por semana (suma de :total agrupada por :semana)
    weekly_hash       = scope.group(:semana).sum(:total)          # { semana => total }
    semanas_ordenadas = weekly_hash.keys.compact.sort
    @semana_labels    = semanas_ordenadas
    @semana_totales   = semanas_ordenadas.map { |s| weekly_hash[s].to_i }

# --- KPIs en texto ---
scope = Ot.all

# Estados
@count_estado_70     = scope.where(estado: 70).count
@count_estado_80_85  = scope.where(estado: [ 80, 85 ]).count
@backlog_ratio       = @count_estado_80_85.zero? ? nil : (@count_estado_70.to_f / @count_estado_80_85)

# Correctivas (F + C)
@ot_correctiva = scope.where(tipo_ot: %w[F C]).count

# Totales (U + A + C + F + I)
@ot_totales_uacfi = scope.where(tipo_ot: %w[U A C F I]).count

# % Correctiva sobre TODOS los registros
@ot_total_all          = scope.count
@pct_correctiva_all    = @ot_total_all.zero? ? 0.0 : ((@ot_correctiva.to_f / @ot_total_all) * 100).round(1)

# % Correctiva sobre U+A+C+F+I
@pct_correctiva_uacfi  = @ot_totales_uacfi.zero? ? 0.0 : ((@ot_correctiva.to_f / @ot_totales_uacfi) * 100).round(1)
  end













  # POST /ots/import
  def import
    file = params[:file]
    unless file.present?
      return redirect_to ots_path, alert: "Selecciona un archivo .xlsx o .csv"
    end

    created = 0
    Dir.mktmpdir do |dir|
      path = File.join(dir, file.original_filename)
      File.open(path, "wb") { |f| f.write(file.read) }
      created = OtsImporter.call(path)
    end

    redirect_to ots_path, notice: "Importadas #{created} filas."
  rescue => e
    redirect_to ots_path, alert: "Error al importar: #{e.message}"
  end

  # GET /ots/1
  def show; end

  # GET /ots/new
  def new
    @ot = Ot.new
  end

  # GET /ots/1/edit
  def edit; end

  # POST /ots
  def create
    @ot = Ot.new(ot_params)

    respond_to do |format|
      if @ot.save
        format.html { redirect_to @ot, notice: "OT creada correctamente." }
        format.json { render :show, status: :created, location: @ot }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ot.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ots/1
  def update
    respond_to do |format|
      if @ot.update(ot_params)
        format.html { redirect_to @ot, status: :see_other, notice: "OT actualizada correctamente." }
        format.json { render :show, status: :ok, location: @ot }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ot.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ots/1
  def destroy
    @ot.destroy!

    respond_to do |format|
      format.html { redirect_to ots_path, status: :see_other, notice: "OT eliminada correctamente." }
      format.json { head :no_content }
    end
  end

  private

  def set_ot
    @ot = Ot.find(params[:id])
  end

  def ot_params
    params.require(:ot).permit(
      :ot_asignada, :semana, :item, :area, :codigo, :actividad_semanal, :esp,
      :frecuencia, :cod_rep, :cantidad, :unitario, :servicio,
      :cotizacion, :cc, :responsable, :contratista, :tipo_ot,
      :estado, :sem_ejec, :n_personas, :duracion_hr, :hh,
      :causa, :comentarios
    )
  end
end
