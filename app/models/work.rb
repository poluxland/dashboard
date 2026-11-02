# app/models/work.rb
class Work < ApplicationRecord
  has_many :inspections, class_name: "WorkInspection", dependent: :destroy, inverse_of: :work
  accepts_nested_attributes_for :inspections, reject_if: ->(attributes) { attributes["id"].blank? && !ActiveModel::Type::Boolean.new.cast(attributes["enabled"]) }

  def selected_inspections
    inspections.select(&:enabled?)
  end

  def prepare_inspections
    WorkInspection::CATALOG.each_key do |key|
      inspection = inspections.find { |entry| entry.template_key == key } || inspections.build(template_key: key, enabled: false)
      inspection.prepare_items
    end
  end

  has_many_attached :fotos
  has_many_attached :fotos_antes
  has_many_attached :fotos_despues

  validate :validar_fotos_tipo_y_peso

  TIPOS_PERMITIDOS = %w[image/png image/jpg image/jpeg image/webp].freeze
  PESO_MAX = 10.megabytes

  private

  def validar_fotos_tipo_y_peso
    %i[fotos fotos_antes fotos_despues].each do |campo|
      public_send(campo).each do |foto|
        unless TIPOS_PERMITIDOS.include?(foto.content_type)
          errors.add(campo, "deben ser PNG/JPG/JPEG/WEBP")
        end
        if foto.byte_size > PESO_MAX
          errors.add(campo, "cada imagen debe pesar menos de 10MB")
        end
      end
    end
  end
end
