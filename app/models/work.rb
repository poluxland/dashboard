# app/models/work.rb
class Work < ApplicationRecord
  has_many_attached :fotos

  validate :validar_fotos_tipo_y_peso

  private

  TIPOS_PERMITIDOS = %w[image/png image/jpg image/jpeg image/webp].freeze
  PESO_MAX = 10.megabytes

  def validar_fotos_tipo_y_peso
    fotos.each do |foto|
      unless TIPOS_PERMITIDOS.include?(foto.content_type)
        errors.add(:fotos, "deben ser PNG/JPG/JPEG/WEBP")
      end
      if foto.byte_size > PESO_MAX
        errors.add(:fotos, "cada imagen debe pesar menos de 10MB")
      end
    end
  end
end
