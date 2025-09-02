# app/models/monthly_record.rb
class MonthlyRecord < ApplicationRecord
  # Normaliza period al primer día del mes
  before_validation :normalize_period_to_month_start

  validates :period, presence: true, uniqueness: true

  with_options presence: true,
               numericality: { only_integer: true, greater_than_or_equal_to: 0 } do
    validates :nomina, :hh, :dp, :actp, :astp, :iap,
              :acreditacion, :salud, :recepcion, :tiempo,
              :soplado, :uso_jetin, :servicios, :despacho
  end

  scope :ordered, -> { order(period: :desc) }

  # Devuelve "YYYY-MM" para mostrar
  def period_ym
    period&.strftime("%Y-%m")
  end

  private

  def normalize_period_to_month_start
    return if period.blank?
    self.period = period.beginning_of_month
  end
end
