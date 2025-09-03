class Person < ApplicationRecord
  has_many :indicator_readings, dependent: :destroy
  validates :name, presence: true, uniqueness: true
end
