class PmmYard < ApplicationRecord
  belongs_to :pmm_material
  validates :nombre, presence: true
  validates :capacidad, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
