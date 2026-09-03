class Mantencion < ApplicationRecord
  before_validation :complete_week_from_date

  validates :fecha, :especialidad, :actividad, presence: true
  validates :semana,
            numericality: { only_integer: true, in: 1..53 },
            allow_nil: true
  validates :estado,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_nil: true
  validates :duracion,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true

  private

  def complete_week_from_date
    self.semana = fecha.cweek if semana.blank? && fecha.present?
  end
end
