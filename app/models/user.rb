class User < ApplicationRecord
  ROLES = %w[member editor support].freeze

  has_secure_password

  attribute :active, :boolean, default: true
  attribute :role, :string, default: "member"

  before_validation { self.email = email.to_s.strip.downcase }

  validates :name, presence: true, length: { maximum: 80 }
  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: ROLES }
  validates :phone, length: { maximum: 20 }, allow_blank: true
  validates :password, length: { minimum: 8 }, allow_blank: true

  scope :search, lambda { |q|
    next all if q.blank?
    like = "%#{sanitize_sql_like(q)}%"
    where("name LIKE :q OR email LIKE :q", q: like)
  }
end
