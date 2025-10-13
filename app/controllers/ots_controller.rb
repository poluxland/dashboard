class OtsController < ApplicationController
  before_action :set_ot, only: %i[ show edit update destroy ]

  # GET /ots
  def index
    @ots = Ot.order(created_at: :desc)
  end



    

  def graficos
    scope = Ot.all

    # --- Tipo OT (%)
    tipo_counts = scope.group(:tipo_ot).count
    total_tipos = tipo_counts.values.sum.nonzero? || 1
    @tipo_labels = tipo_counts.keys.map { |k| k.presence || "Sin tipo" }
    @tipo_values = tipo_counts.values.map { |v| ((v.to_f / total_tipos) * 100).round(1) }

    # --- Estado (%)
    estado_counts = scope.group(:estado).count
    total_estados = estado_counts.values.sum.nonzero? || 1
    @estado_labels = estado_counts.keys.map { |k| k.presence || "Sin estado" }
    @estado_values = estado_counts.values.map { |v| ((v.to_f / total_estados) * 100).round(1) }
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
