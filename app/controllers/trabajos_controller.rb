class TrabajosController < ApplicationController
  before_action :require_trabajos_access!
  before_action :set_trabajo, only: %i[show edit update]

  def index
    @filters = params.permit(:planta, :avance, :mes, :op, :q).to_h
    scope = filtered_trabajos
    ordered = scope.order(created_at: :desc, id: :desc)

    respond_to do |format|
      format.html do
        @total = scope.sum(:total)
        @pagy, @trabajos = pagy(ordered, limit: 30)
      end
      format.xlsx do
        @trabajos = ordered
        response.headers["Content-Disposition"] = 'attachment; filename="cotizaciones-impromaq.xlsx"'
        response.headers["Cache-Control"] = "no-store"
      end
    end
  end

  def show
  end

  def new
    @trabajo = Trabajo.new(avance: "Cotizada")
  end

  def create
    @trabajo = Trabajo.new(trabajo_params.merge(author_email: current_user[:email].to_s.strip.downcase))
    if @trabajo.save
      redirect_to @trabajo, notice: "Cotización #{@trabajo.referencia} creada.", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @trabajo.update(trabajo_params)
      redirect_to @trabajo, notice: "Trabajo actualizado.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def require_trabajos_access!
    head :forbidden unless trabajos_access?
  end

  def filtered_trabajos
    scope = Trabajo.all
    scope = scope.where(planta: @filters[:planta]) if @filters[:planta].present?
    scope = case @filters[:avance]
    when "finalizados" then scope.finalizados
    when "sin_estado" then scope.where(avance: [ nil, "" ])
    else @filters[:avance].present? ? scope.where(avance: @filters[:avance]) : scope
    end

    if @filters[:mes].to_s.match?(/\A[1-9]\d{3}-(0[1-9]|1[0-2])\z/)
      scope = scope.where(fecha_termino: Date.iso8601("#{@filters[:mes]}-01").all_month)
    end
    scope = scope.sin_op if @filters[:op] == "sin"
    scope = scope.con_op if @filters[:op] == "con"
    return scope if @filters[:q].blank?

    query = @filters[:q].strip
    match = "%#{Trabajo.sanitize_sql_like(query)}%"
    matches = scope.where("descripcion ILIKE :match OR ito ILIKE :match OR centro_costo ILIKE :match", match: match)
    if query.match?(/\A\d{1,18}\z/)
      matches.or(scope.where(erp_id: query)).or(scope.where(op: query)).or(scope.where(factura: query))
    elsif query.match?(/\AD-\d{1,18}\z/i)
      matches.or(scope.where(id: query[2..], erp_id: nil))
    else
      matches
    end
  end

  def set_trabajo
    @trabajo = Trabajo.find(params[:id])
  end

  def trabajo_params
    params.expect(trabajo: [
      :planta, :ito, :descripcion, :fecha_termino, :avance, :op, :factura,
      :observaciones, :centro_costo, :supervisor, :otros, :detalle, *Trabajo::ITEM_FIELDS
    ])
  end
end
