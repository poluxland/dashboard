class TaskItem < ApplicationRecord
  belongs_to :task
  validates :title, :due_on, presence: true
  validates :title, length: { maximum: 200 }
end
