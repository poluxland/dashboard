class Enfundado < ApplicationRecord
  validates :operador, :turno, presence: true
  validates :fecha, presence: true

  validates :turno, uniqueness: {
    scope: :fecha,
    message: "ya existe para esa fecha"
  }
end