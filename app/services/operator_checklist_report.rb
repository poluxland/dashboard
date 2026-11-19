class OperatorChecklistReport
  CHILE = Time.find_zone!("America/Santiago")
  SHORT_LABELS = {
    c1: "Fugas", c2: "Pernos/quebraduras", c3: "Movimientos", c4: "Frenos", c5: "Pasadores",
    c6: "Espejos", c7: "Cinturón", c8: "Neumáticos", c9: "Alarma de retroceso", c10: "Bocina",
    c11: "Luces", c12: "Alarmas", c13: "Engrase", c14: "Parabrisas", c15: "Pértiga", c16: "Extintor"
  }.freeze
  Row = Data.define(:equipment, :checked_at, :hour_meter, :score, :severe, :minor, :comments)

  attr_reader :plant, :window

  def initialize(plant:, scheduled_at:)
    @plant = plant
    local_time = scheduled_at.in_time_zone(CHILE)
    @window = if plant == "LCA"
      (local_time - 8.hours)...local_time
    else
      local_time.yesterday.beginning_of_day...local_time.beginning_of_day
    end
  end

  def plant_name
    EquipmentChecklist::PLANTS.fetch(plant)
  end

  def rows
    checklists = EquipmentChecklist.where(c17: plant, created_at: window)
      .includes(:mobile_asset).order(created_at: :desc, id: :desc).to_a
    checklists = latest_per_equipment(checklists) if plant == "LCA"
    checklists.map { |checklist| summarize(checklist) }
  end

  private

  def latest_per_equipment(checklists)
    codes = MobileAsset.pluck(:code, :id).group_by { |code, _| normalize_code(code) }
    checklists.uniq do |checklist|
      code = normalize_code(checklist.legacy_code)
      matches = codes[code]
      asset_id = checklist.mobile_asset_id || (matches.first.last if code.present? && matches&.one?)
      asset_id || code.presence || [ :unknown, checklist.id ]
    end
  end

  def normalize_code(code)
    code.to_s.strip.downcase
  end

  def summarize(checklist)
    severe = []
    minor = []
    passed = 0
    SHORT_LABELS.each do |field, label|
      case checklist[field]
      when "Si" then passed += 1
      when "No(grave)" then severe << label
      when "No(leve)", "No" then minor << label
      end
    end
    applicable = passed + severe.size + minor.size
    score = 100.0 * (passed + 0.5 * minor.size) / applicable if applicable.positive?

    Row.new(checklist.asset_label, checklist.created_at.in_time_zone(CHILE), checklist.hour_meter,
            score, severe, minor, checklist.comments)
  end
end
