class WorkInspectionItem < ApplicationRecord
  ANSWERS = { "yes" => "Cumple", "no" => "No cumple", "na" => "No aplica" }.freeze

  belongs_to :work_inspection, inverse_of: :items
  has_many_attached :fotos
  attr_readonly :question
  validate { errors.add(:position, "no puede cambiar") if persisted? && position_changed? }
  before_validation :set_question, on: :create
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, uniqueness: { scope: :work_inspection_id }
  validates :question, presence: true
  validates :answer, inclusion: { in: ANSWERS.keys }, allow_blank: true
  validate :valid_position
  validate :validate_photos

  def fotos_uploads=(uploads)
    uploads = Array(uploads).reject(&:blank?)
    self.fotos = fotos.blobs.to_a + uploads if uploads.any?
  end

  def answer_label
    ANSWERS[answer] || "Sin responder"
  end

  def reported?
    answer.present? || observations.present? || fotos.attached?
  end

  private

  def set_question
    self.question = WorkInspection::CATALOG.dig(work_inspection.template_key, "items")&.at(position) if position && position >= 0
  end

  def valid_position
    questions = WorkInspection::CATALOG.dig(work_inspection.template_key, "items") || []
    errors.add(:position, "no corresponde a esta inspección") unless position && position.between?(0, questions.length - 1)
  end

  def validate_photos
    fotos.each do |photo|
      errors.add(:fotos, "deben ser PNG/JPG/JPEG/WEBP") unless Work::TIPOS_PERMITIDOS.include?(photo.content_type)
      errors.add(:fotos, "cada imagen debe pesar menos de 10MB") if photo.byte_size > Work::PESO_MAX
    end
  end
end
