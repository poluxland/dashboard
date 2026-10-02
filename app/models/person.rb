class Person < ApplicationRecord
  scope :for_indicators, -> { where(indicator_enabled: true) }

  normalizes :area, with: ->(area) { area.strip.presence }
  validates :area, presence: true, if: -> { new_record? || area_changed? }

  has_many :indicator_readings, dependent: :destroy
  validates :name, presence: true, uniqueness: true
end
