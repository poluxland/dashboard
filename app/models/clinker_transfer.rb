class ClinkerTransfer < ApplicationRecord
  validates :date, :author_email, presence: true
  validates :date, uniqueness: true
  validates :tons, numericality: { greater_than_or_equal_to: 0, less_than: 100_000_000_000 }
  validates :observations, length: { maximum: 5000 }
  validate :date_not_in_future

  private

  def date_not_in_future
    errors.add(:date, "no puede ser futura") if date && date > Date.current
  end
end
