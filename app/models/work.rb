# app/models/work.rb
class Work < ApplicationRecord
  has_many_attached :fotos
  has_many_attached :fotos_antes
  has_many_attached :fotos_despues

  validate :validar_fotos_tipo_y_peso

  private

  TIPOS_PERMITIDOS = %w[image/png image/jpg image/jpeg image/webp].freeze
  PESO_MAX = 10.megabytes

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
