class WorkInspection < ApplicationRecord
  CATALOG = JSON.parse(Rails.root.join("config/work_inspections.json").read).freeze

  belongs_to :work, inverse_of: :inspections
  has_many :items, -> { order(:position) }, class_name: "WorkInspectionItem", dependent: :destroy, inverse_of: :work_inspection
  accepts_nested_attributes_for :items

  validates :template_key, inclusion: { in: CATALOG.keys }, uniqueness: { scope: :work_id }
  attr_readonly :title
  validate { errors.add(:template_key, "no puede cambiar") if persisted? && template_key_changed? }
  before_validation :prepare_items

  def prepare_items
    template = CATALOG[template_key]
    return unless template

    self.title ||= template.fetch("title")
    template.fetch("items").each_with_index do |question, position|
      items.build(position: position, question: question) unless items.any? { |item| item.position == position }
    end
  end

  def summary
    total = items.size
    reviewed = items.count { |item| item.answer.present? }
    failed = items.count { |item| item.answer == "no" }
    applicable = items.count { |item| %w[yes no].include?(item.answer) }
    passed = items.count { |item| item.answer == "yes" }
    state = if reviewed.zero?
      "Sin iniciar"
    elsif reviewed < total
      "Incompleta"
    elsif failed.positive?
      "Con hallazgos"
    elsif applicable.zero?
      "No aplica"
    else
      "Cumple"
    end
    { total: total, reviewed: reviewed, failed: failed, state: state,
      compliance: applicable.positive? ? (100.0 * passed / applicable).round : nil }
  end
end
