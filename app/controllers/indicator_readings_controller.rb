# app/controllers/indicator_readings_controller.rb
class IndicatorReadingsController < ApplicationController
  before_action :set_reading, only: [ :edit, :update ]
  before_action :load_people, only: [ :index, :new, :edit, :matrix ]

def index
  @month = params[:month].presence && Date.strptime("#{params[:month]}-01", "%Y-%m-%d") rescue nil

  # ---- Listado con filtros (OK con includes porque no restringimos select) ----
  scope = IndicatorReading.includes(:person).order(period: :desc)
  scope = scope.where(period: @month.beginning_of_month..@month.end_of_month) if @month
  scope = scope.where(person_id: params[:person_id]) if params[:person_id].present?
  @readings = scope

  # --------------------------------------------------------------------------
  # Tendencia mensual (promedio por indicador)  -> series: Cuasi, LVS, CC, HH
  # Usamos pluck para evitar instanciar registros con columnas parciales.
  # --------------------------------------------------------------------------
  trend_scope = IndicatorReading
  trend_scope = trend_scope.where(person_id: params[:person_id]) if params[:person_id].present?

  trend_rows = trend_scope
                 .group(:period)
                 .order(:period)
                 .pluck(
                   :period,
                   Arel.sql("AVG(cuasi)"),
                   Arel.sql("AVG(lvs)"),
                   Arel.sql("AVG(cc)"),
                   Arel.sql("AVG(hh)")
                 )

  @trend_labels   = trend_rows.map { |period, *_| period.strftime("%Y-%m") }
  cuasi_series    = trend_rows.map { |_, cu, _, _, _| cu.to_f }
  lvs_series      = trend_rows.map { |_, _, lv, _, _| lv.to_f }
  cc_series       = trend_rows.map { |_, _, _, c, _| c.to_f }
  hh_series       = trend_rows.map { |_, _, _, _, h| h.to_f }

  @trend_datasets = [
    { label: "Cuasi", data: cuasi_series },
    { label: "LVS",   data: lvs_series   },
    { label: "CC",    data: cc_series    },
    { label: "HH",    data: hh_series    }
  ]

  # ---------------------------------------------------------------------------------
  # Evolución del PROMEDIO por persona (una serie por persona a través de los meses)
  # promedio = (cuasi + lvs + cc + hh) / 4. Usamos pluck y agrupamos en Ruby.
  # ---------------------------------------------------------------------------------
  avg_base = IndicatorReading.order(:period)
  avg_base = avg_base.where(person_id: params[:person_id]) if params[:person_id].present?

  periods = avg_base.distinct.order(:period).pluck(:period)
  @avg_people_labels = periods.map { |d| d.strftime("%Y-%m") }

  rows = avg_base.pluck(
    :person_id,
    :period,
    Arel.sql("((COALESCE(cuasi,0)+COALESCE(lvs,0)+COALESCE(cc,0)+COALESCE(hh,0))/4.0)")
  )
  # rows => [[person_id, period, avg_person], ...]

  person_ids = rows.map(&:first).uniq
  names = Person.where(id: person_ids).pluck(:id, :name).to_h

  grouped = rows.group_by { |pid, _period, _avg| pid }
  @avg_people_datasets = grouped.map do |pid, arr|
    # Hash periodo -> promedio
    values_by_period = arr.each_with_object({}) { |(_pid, per, avg), h| h[per] = avg.to_f }
    {
      label: names[pid] || "ID #{pid}",
      data: periods.map { |p| values_by_period[p] || nil } # alineado a labels; permite gaps
    }
  end

  # --------------------------------------------------------------------------
  # Barras por persona (solo si hay mes filtrado) -> series: Cuasi, LVS, CC, HH
  # Aquí sí usamos includes(:person) porque NO restringimos select.
  # --------------------------------------------------------------------------
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

  people = Person.arel_table

scope = IndicatorReading.joins(:person)
scope = scope.where(period: @month.all_month) if @month.present?

rows = scope
  .group(people[:planta]) # equivale a GROUP BY people.planta
  .pluck(
    Arel.sql("COALESCE(people.planta, '-')"),             # etiqueta
    Arel.sql("AVG(indicator_readings.cuasi)"),
    Arel.sql("AVG(indicator_readings.lvs)"),
    Arel.sql("AVG(indicator_readings.cc)"),
    Arel.sql("AVG(indicator_readings.hh)")
  )

@plants_labels = rows.map { |pl, *_| pl }
cuasi_data = rows.map { |_, a, *_| a.to_f.round(0) }
lvs_data   = rows.map { |_, _, b, *_| b.to_f.round(0) }
cc_data    = rows.map { |_, _, _, c, _| c.to_f.round(0) }
hh_data    = rows.map { |_, _, _, _, d| d.to_f.round(0) }

@plants_datasets = [
  { label: "Cuasi", data: cuasi_data },
  { label: "LVS",   data: lvs_data   },
  { label: "CC",    data: cc_data    },
  { label: "HH",    data: hh_data    }
]
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
# app/controllers/indicator_readings_controller.rb
def matrix
  @month =
    begin
      if params[:month].present?
        Date.strptime("#{params[:month]}-01", "%Y-%m-%d")
      else
        Date.current.beginning_of_month
      end
    rescue ArgumentError
      Date.current.beginning_of_month
    end

  range = @month.beginning_of_month..@month.end_of_month

  existing = IndicatorReading.where(period: range)
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
