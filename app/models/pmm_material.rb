class PmmMaterial < ApplicationRecord
  has_many :pmm_trucks, dependent: :restrict_with_error
  has_many :pmm_yards, dependent: :restrict_with_error
  validates :nombre, presence: true
  validates :densidad, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
