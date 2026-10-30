class TptImport < ApplicationRecord
  has_many :tpt_events, dependent: :restrict_with_exception
  validates :filename, :author_email, presence: true
end
