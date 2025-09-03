# app/controllers/indicator_readings_controller.rb
class IndicatorReadingsController < ApplicationController
  before_action :set_reading, only: [ :edit, :update ]
  before_action :load_people, only: [ :index, :new, :edit, :matrix ]

  def index
    @month = params[:month].presence && Date.strptime("#{params[:month]}-01", "%Y-%m-%d") rescue nil
    scope = IndicatorReading.includes(:person).order(period: :desc)
    scope = scope.where(period: @month.beginning_of_month..@month.end_of_month) if @month
    scope = scope.where(person_id: params[:person_id]) if params[:person_id].present?
    @readings = scope
# ---- Tendencia mensual (promedio por indicador) ----
trend_rows = IndicatorReading
  .group(:period)
  .select("period, AVG(cuasi) AS cuasi, AVG(lvs) AS lvs, AVG(cc) AS cc, AVG(hh) AS hh")
  .order(:period)

@trend_labels = trend_rows.map { |r| r.period.strftime("%Y-%m") }
@trend_datasets = [
  { label: "Cuasi", data: trend_rows.map { |r| r.cuasi.to_f } },
  { label: "LVS",   data: trend_rows.map { |r| r.lvs.to_f } },
  { label: "CC",    data: trend_rows.map { |r| r.cc.to_f } },
  { label: "HH",    data: trend_rows.map { |r| r.hh.to_f } }
]

# ---- Barras por persona (cuando hay mes filtrado) ----
if @month
  month_scope = IndicatorReading.for_month(@month).includes(:person).order("people.name")
  @bar_labels = month_scope.map { |r| r.person.name }
  @bar_datasets = [
    { label: "Cuasi", data: month_scope.map { |r| r.cuasi.to_f } },
    { label: "LVS",   data: month_scope.map { |r| r.lvs.to_f } },
    { label: "CC",    data: month_scope.map { |r| r.cc.to_f } },
    { label: "HH",    data: month_scope.map { |r| r.hh.to_f } }
  ]
end
  end

  def new
    @reading = IndicatorReading.new(period: Date.current.beginning_of_month)
  end

  def create
    @reading = IndicatorReading.new(permitted_params)
    if @reading.save
      redirect_to indicator_readings_path, notice: "Lectura creada."
    else
      load_people
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @reading.update(permitted_params)
      redirect_to indicator_readings_path, notice: "Lectura actualizada."
    else
      load_people
      render :edit, status: :unprocessable_entity
    end
  end

  # -------- Planilla mensual --------
  def matrix
    @month = params[:month].presence && Date.strptime("#{params[:month]}-01", "%Y-%m-%d") rescue Date.current.beginning_of_month
    existing = IndicatorReading.where(period: @month.beginning_of_month..@month.end_of_month)
                               .pluck(:person_id, :cuasi, :lvs, :cc, :hh)
    @by_person = existing.each_with_object(Hash.new { |h, k| h[k] = {} }) do |(pid, cu, lv, cc, hh), h|
      h[pid] = { cuasi: cu, lvs: lv, cc: cc, hh: hh }
    end
  end

  def matrix_save
    month = Date.strptime("#{params[:month]}-01", "%Y-%m-%d") rescue nil
    return redirect_to matrix_indicator_readings_path, alert: "Mes inválido" unless month

    rows = params[:rows] || {} # { person_id => {cuasi:"", lvs:"", cc:"", hh:""} }
    now  = Time.current
    upserts = rows.map do |pid, vals|
      {
        person_id: pid.to_i,
        period: month.beginning_of_month,
        cuasi: to_num(vals[:cuasi]),
        lvs:   to_num(vals[:lvs]),
        cc:    to_num(vals[:cc]),
        hh:    to_num(vals[:hh]),
        created_at: now, updated_at: now
      }
    end

    IndicatorReading.upsert_all(upserts, unique_by: :idx_unique_person_period)
    redirect_to matrix_indicator_readings_path(month: month.strftime("%Y-%m")), notice: "Planilla guardada."
  end

  private

  def set_reading
    @reading = IndicatorReading.find(params[:id])
  end

  def load_people
    @people = Person.order(:name)
  end

  # Acepta month "YYYY-MM" y campos *_string (opcional)
  def permitted_params
    p = params.require(:indicator_reading)
              .permit(:person_id, :period, :cuasi, :lvs, :cc, :hh,
                      :cuasi_string, :lvs_string, :cc_string, :hh_string)

    # soportar escritura "YYYY-MM"
    if p[:period].present? && p[:period] =~ /\A\d{4}-\d{2}\z/
      p[:period] = Date.strptime("#{p[:period]}-01", "%Y-%m-%d")
    end

    # si vienen *_string conviértelos a número
    %i[cuasi lvs cc hh].each do |k|
      s = p.delete("#{k}_string")
      p[k] = to_num(s) if s.present?
    end

    p
  end

  def to_num(v)
    v.to_s.delete("%").tr(",", ".").to_f if v.present?
  end
end
