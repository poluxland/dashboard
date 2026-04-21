class Enfundado < ApplicationRecord
  validates :operador, presence: true
  validates :turno, presence: true
end