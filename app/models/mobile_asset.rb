class MobileAsset < ApplicationRecord
  has_many :equipment_checklists, dependent: :restrict_with_error
  has_many :maintenance_checklists, dependent: :restrict_with_error

  validates :code, presence: true

  def label
    code.presence || "Equipo ##{id}"
  end

  def checklist_history(model = EquipmentChecklist)
    history = model.where(mobile_asset_id: id)
    return history if code.blank? || MobileAsset.where("LOWER(TRIM(code)) = ?", code.strip.downcase).count != 1

    history.or(model.where(mobile_asset_id: nil).where("LOWER(TRIM(legacy_code)) = ?", code.strip.downcase))
  end
end
