class Task < ApplicationRecord
  STATUSES = { "pending" => "Pendiente", "in_progress" => "En curso", "done" => "Terminada" }.freeze
  PRIORITIES = { "normal" => "Normal", "high" => "Alta", "urgent" => "Urgente" }.freeze
  normalizes :assignee_email, :creator_email, with: ->(email) { email.strip.downcase }
  validates :title, :assignee_email, :creator_email, presence: true
  validates :title, length: { maximum: 200 }
  validates :assignee_email, format: { with: /\A[^\s@]+@msindustrial\.cl\z/ }
  validates :status, inclusion: { in: STATUSES.keys }
  validates :priority, inclusion: { in: PRIORITIES.keys }
  scope :ordered, -> { order(Arel.sql("due_on ASC NULLS LAST"), created_at: :desc) }
end
