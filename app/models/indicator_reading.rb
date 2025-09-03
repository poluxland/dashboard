# app/models/indicator_reading.rb
class IndicatorReading < ApplicationRecord
  belongs_to :person

  before_validation :normalize_period_to_month_start

  validates :period, presence: true
  validates :cuasi, :lvs, :cc, :hh, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered,   -> { order(period: :desc) }
  scope :for_month, ->(date) { where(period: date.beginning_of_month..date.end_of_month) }

  # helpers opcionales para escribir "107" o "107%":
  def cuasi_string=(s); self.cuasi = to_num(s); end
  def lvs_string=(s);   self.lvs   = to_num(s); end
  def cc_string=(s);    self.cc    = to_num(s); end
  def hh_string=(s);    self.hh    = to_num(s); end

  def cuasi_string; cuasi&.to_f; end
  def lvs_string;   lvs&.to_f;   end
  def cc_string;    cc&.to_f;    end
  def hh_string;    hh&.to_f;    end

  private

  def normalize_period_to_month_start
    self.period = period.beginning_of_month if period.present?
  end

  def to_num(s)
    s.to_s.delete("%").tr(",", ".").to_f if s.present?
  end
end
