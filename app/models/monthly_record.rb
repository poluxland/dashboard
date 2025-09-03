class MonthlyRecord < ApplicationRecord
  METRICS = %i[
    nomina hh dp actp astp iap
    acreditacion salud recepcion tiempo
    soplado uso_jetin servicios despacho
  ].freeze

  # Normaliza period al primer día del mes
  before_validation :normalize_period_to_month_start

  validates :period, presence: true, uniqueness: { message: "ya existe un registro para ese mes" }

  with_options presence: true,
               numericality: { only_integer: true, greater_than_or_equal_to: 0 } do
    validates(*METRICS)
  end

  scope :ordered, -> { order(period: :desc) }
  scope :last_12_months, -> {
    where(period: 12.months.ago.beginning_of_month..Date.current.end_of_month)
  }

  # Devuelve/recibe "YYYY-MM" (útil en forms con month_field)
  def period_ym
    period&.strftime("%Y-%m")
  end

  def period_ym=(val)
    self.period =
      begin
        Date.strptime("#{val}-01", "%Y-%m-%d") if val.present?
      rescue ArgumentError
        nil
      end
  end

  # ----- Agregaciones para gráficos -----

  # Una sola query con SUM(...) de todas las métricas agrupadas por month(period)
  def self.sums_grouped_by_period(relation = all)
    selects = [ "period" ] + METRICS.map { |m| "SUM(#{m}) AS sum_#{m}" }
    relation.except(:select, :order)
            .group(:period)
            .select(selects.join(", "))
            .order(:period)
  end

  # Retorna [labels, datasets] listos para Chart.js
  # datasets => [{label: "HH", data: [..]}, ...]
  def self.chart_data(relation = all, only: METRICS, labels: nil)
    rows = sums_grouped_by_period(relation)
    labels ||= rows.map { |r| r.period.strftime("%Y-%m") }
    datasets = only.map do |m|
      { label: m.to_s.humanize, data: rows.map { |r| r["sum_#{m}"].to_i } }
    end
    [ labels, datasets ]
  end

  private

  def normalize_period_to_month_start
    return if period.blank?
    self.period = period.beginning_of_month
  end
end
