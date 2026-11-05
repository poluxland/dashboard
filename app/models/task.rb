class Task < ApplicationRecord
  CATEGORIES = { "safety" => "Seguridad", "people" => "Personas", "operations" => "Operaciones", "other" => "Otro" }.freeze
  PLANTS = %w[LCA PTM VTS N/A].freeze
  has_many :comments, class_name: "TaskComment", dependent: :destroy
  has_many :items, class_name: "TaskItem", dependent: :destroy
  has_many :notifications, class_name: "TaskNotification", dependent: :destroy
  accepts_nested_attributes_for :items, allow_destroy: true, reject_if: :all_blank
  validates :category, inclusion: { in: CATEGORIES.keys }
  validates :plant, inclusion: { in: PLANTS }
  before_save :sync_checklist_status
  after_create :queue_assignment
  after_update :queue_assignment, if: :saved_change_to_assignee_email?

  def completion_percentage
    return 0 if items.empty?
    (100.0 * items.count(&:completed?) / items.size).round
  end

  private

  def sync_checklist_status
    checklist = items.to_a
    return unless checklist.any? { |item| item.new_record? || item.marked_for_destruction? || item.will_save_change_to_completed? }

    remaining = checklist.reject(&:marked_for_destruction?)
    if remaining.any? && remaining.all?(&:completed?)
      self.status = "done"
    elsif status == "done" && remaining.any? { |item| !item.completed? }
      self.status = "in_progress"
    end
  end

  def queue_assignment
    notifications.create!(kind: "assigned", recipient: assignee_email, deduplication_key: "assigned:#{id}:#{SecureRandom.uuid}")
  end

  public

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
