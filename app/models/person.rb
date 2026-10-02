class Person < ApplicationRecord
  normalizes :area, with: ->(area) { area.strip.presence }
  validates :area, presence: true, if: -> { new_record? || area_changed? }

  has_many :indicator_readings, dependent: :destroy
  validates :name, presence: true, uniqueness: true
end
