class Admin < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :validatable

  # Virtual attribute: the invite code typed on the sign up form
  attr_accessor :invite_code

  validates :name, presence: true, length: { maximum: 80 }
  validate :invite_code_must_match, on: :create

  private

  # Fails closed: if ADMIN_INVITE_CODE is not set, nobody can sign up.
  def invite_code_must_match
    expected = ENV["ADMIN_INVITE_CODE"].to_s
    valid = expected.present? &&
            ActiveSupport::SecurityUtils.secure_compare(invite_code.to_s, expected)
    errors.add(:invite_code, "is invalid") unless valid
  end
end
