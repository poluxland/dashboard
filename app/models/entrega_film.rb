# app/models/entrega_film.rb
class EntregaFilm < ApplicationRecord
  validates :fecha, presence: true

  validates :rollos_entregados,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true

  def total_rollos
    rollos_entregados.to_i
  end
end