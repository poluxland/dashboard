class EnvasadoraReport < ApplicationRecord
  CEMENTS = [ "Especial", "Extra", "Ultra", "S3300", "S4200", "Plus", "S3300 (AR)", "HPM", "Extramix" ].freeze
  SHIFTS = { "TM" => "Turno Mañana", "TT" => "Turno Tarde", "TN" => "Turno Noche" }.freeze
  GROUPS = JSON.parse(Rails.root.join("config/envasadora_fields.json").read).freeze
  FIELDS = GROUPS.values.flatten.freeze
  SILOS = {
    19 => { readings: %w[silo19a silo19b], height: 30, factor: 100 },
    20 => { readings: %w[silo20a silo20b], height: 30, factor: 100 },
    21 => { readings: %w[silo21a silo21b], height: 30, factor: 100 },
    22 => { readings: %w[silo22a silo22b], height: 30, factor: 100 },
    27 => { readings: %w[silo27], height: 30, factor: 460 },
    28 => { readings: %w[silo28], height: 20, factor: 100 }
  }.freeze
  HOPPERS = [
    [ "Silo 28 calle 5", "tolvacalle5", "otros", 150 ],
    [ "Silos 3000 tolva 1", "silos3000tolva1", "ns30001", 150 ],
    [ "Silos 3000 tolva 4", "silos3000tolva4", "ns30002", 75 ],
    [ "Silos 3000 tolva 5", "silos3000tolva5", "ns30003", 75 ],
    [ "Bigbag 1", "silosbigbag1", "nbb1", 150 ],
    [ "Bigbag 2", "silosbigbag2", "nbb2", 150 ],
    [ "Vento 1", "silosvento1", "nvento1", 150 ],
    [ "Vento 2", "silovento2", "nvento2", 150 ],
    [ "Vento 3", "silovento3", "nvento3", 150 ]
  ].freeze
  FLOOR = { "Extra" => %w[extrsacos bigbagextra bigbagextra1 bigbagextra1350], "Ultra" => %w[bigbag_extra_retiro], "Especial" => %w[especialsacos bigbagespecial], "S4200" => %w[bigbagsuper], "Plus" => %w[bigbagplus] }.freeze
  RECIPIENTS = JSON.parse(Rails.root.join("config/envasadora_recipients.json").read).freeze
  INPUT_FIELDS = (FIELDS.map { |f| f.fetch("name") } + SILOS.flat_map { |id, s| s[:readings] + [ "silo#{id}_cement" ] } + %w[date turno observations]).freeze

  # Keep historical readings intact; new or edited quantities must be whole numbers.
  validate :whole_number_inputs

  validates :date, :author_email, presence: true
  validates :turno, inclusion: { in: SHIFTS.keys }
  SILOS.each do |id, silo|
    validates "silo#{id}_cement", inclusion: { in: CEMENTS }
    validates(*silo[:readings], numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: silo[:height] })
  end
  FIELDS.each do |field|
    if field["choices"]
      validates field["name"], inclusion: { in: field["choices"] }, allow_blank: field["choices"].first.is_a?(String)
    elsif field["kind"] == "number"
      validates field["name"], numericality: { greater_than_or_equal_to: 0 }
    else
      validates field["name"], length: { maximum: 2000 }
    end
  end
  HOPPERS.each do |_label, cement, level, _capacity|
    validates cement, presence: true, if: -> { public_send(level).to_d.positive? }
  end
  validates :observations, length: { maximum: 10000 }

  def silo_tons(id)
    silo = SILOS.fetch(id)
    (silo[:height] - silo[:readings].sum { |field| public_send(field) } / silo[:readings].size) * silo[:factor]
  end

  def inventory
    CEMENTS.to_h do |cement|
      silo = SILOS.keys.select { |id| public_send("silo#{id}_cement") == cement }.sum { |id| silo_tons(id) }
      floor = FLOOR.fetch(cement, []).sum { |field| public_send(field) }
      [ cement, { silo: silo, floor: floor, total: silo + floor } ]
    end
  end

  def total_tons
    inventory.values.sum { |row| row[:total] }
  end

  # A stock snapshot is never added to another shift's snapshot.
  def daily_reports
    earlier = SHIFTS.keys.take(SHIFTS.keys.index(turno))
    reports = self.class.where(date: date, turno: earlier).where("created_at <= ?", created_at).order(:created_at, :id).index_by(&:turno)
    reports.merge(turno => self)
  end

  def whole_number_inputs
    numeric_fields = FIELDS.select { |field| field["kind"] == "number" }.map { |field| field["name"] } + SILOS.values.flat_map { |silo| silo[:readings] }
    numeric_fields.each do |field|
      next unless new_record? || will_save_change_to_attribute?(field)

      value = public_send(field)
      errors.add(field, "debe ser un número entero") if value.is_a?(Numeric) && value != value.to_i
    end
  end

  def recipients
    RECIPIENTS.dup
  end
end
