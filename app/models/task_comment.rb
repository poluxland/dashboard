class TaskComment < ApplicationRecord
  belongs_to :task
  normalizes :body, with: ->(body) { body.strip }
  validates :body, :author_email, presence: true
  validates :body, length: { maximum: 5000 }
  scope :chronological, -> { order(:created_at, :id) }
end
