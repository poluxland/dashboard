class PtmEvent < ApplicationRecord
  belongs_to :ptm_report, inverse_of: :ptm_events
  validates :equipment, presence: true
  validates :minutes, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :minutes, presence: true, unless: -> { ptm_report&.source_key.present? }
  validates :reason, length: { maximum: 10000 }
  before_validation { self.equipment = PtmEquipment.normalize(equipment) }
end
