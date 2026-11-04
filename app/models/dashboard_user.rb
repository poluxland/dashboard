class DashboardUser < ApplicationRecord
  normalizes :email, with: ->(email) { email.strip.downcase }
  validates :email, presence: true, uniqueness: true

  def self.record_login(user)
    email = user[:email].to_s.strip.downcase
    upsert({ email: email, name: user[:name] }, unique_by: :email)
  end

  def self.responsible_options
    order(:name, :email).map { |user| [ user.name.present? ? "#{user.name} · #{user.email}" : user.email, user.email ] }
  end
end
