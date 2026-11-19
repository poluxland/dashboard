class EstadoCanchasController < ApplicationController
  before_action :set_estado_cancha, only: %i[show edit update destroy]

  def index
    scope = EstadoCancha.recent_first
    @estado_canchas = scope.limit(10).to_a
    @latest = @estado_canchas.first
    @trend = scope.limit(60).to_a.reverse

    respond_to do |format|
      format.html
      format.json { render json: @estado_canchas.map { |record| as_resource(record) } }
    end
  end

  def historial
    dates = params.permit(:desde, :hasta)
    @from = dates[:desde].presence
    @to = dates[:hasta].presence
    scope = EstadoCancha.recent_first
    from = local_midnight(@from)
    to = local_midnight(@to, next_day: true)
    scope = scope.where(created_at: from..) if from
    scope = scope.where(created_at: ...to) if to
    @pagy, @estado_canchas = pagy(scope, limit: 30)
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: as_resource(@estado_cancha) }
    end
  end

  def new
    @estado_cancha = EstadoCancha.new
  end

  def create
    @estado_cancha = EstadoCancha.new(estado_cancha_params)
    if @estado_cancha.save
      EstadoCanchaMailer.status(@estado_cancha).deliver_later if EstadoCanchaMailer.recipients.any?
      respond_to do |format|
        format.html { redirect_to estado_canchas_path, notice: "Estado de canchas guardado.", status: :see_other }
        format.json { render json: as_resource(@estado_cancha), status: :created, location: @estado_cancha }
      end
    else
      render_invalid(:new)
    end
  end

  def edit
  end

  def update
    if @estado_cancha.update(estado_cancha_params)
      respond_to do |format|
        format.html { redirect_to @estado_cancha, notice: "Estado de canchas actualizado.", status: :see_other }
        format.json { render json: as_resource(@estado_cancha) }
      end
    else
      render_invalid(:edit)
    end
  end

  def destroy
    @estado_cancha.destroy!
    respond_to do |format|
      format.html { redirect_to estado_canchas_path, notice: "Registro eliminado.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_estado_cancha
    @estado_cancha = EstadoCancha.find(params.expect(:id))
  end

  def estado_cancha_params
    params.expect(estado_cancha: EstadoCancha::FIELDS)
  end

  def as_resource(record)
    record.as_json(only: [ :id, :created_at, :updated_at, *EstadoCancha::FIELDS ]).merge(
      "url" => estado_cancha_url(record, format: :json)
    )
  end

  def render_invalid(template)
    respond_to do |format|
      format.html { render template, status: :unprocessable_entity }
      format.json { render json: @estado_cancha.errors, status: :unprocessable_entity }
    end
  end

  def local_midnight(value, next_day: false)
    return unless value.is_a?(String)

    date = Date.iso8601(value)
    date += 1 if next_day
    EstadoCancha::CHILE.local(date.year, date.month, date.day)
  rescue ArgumentError
    nil
  end
end
