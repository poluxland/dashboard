class TptEvent < ApplicationRecord
  belongs_to :tpt_import
  validates :impact, :production_state, :reason, :started_at, :source_fingerprint, presence: true
  validates :duration_seconds, numericality: true

  scope :nonnegative, -> { where("duration_seconds >= 0") }
end
