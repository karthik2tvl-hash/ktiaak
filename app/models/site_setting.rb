# Single-row table: there is only ever one set of site settings.
class SiteSetting < ApplicationRecord
  attribute :primary_color, :string, default: "#6c7bff"
  attribute :maintenance_mode, :boolean, default: false

  validates :site_name, presence: true, length: { maximum: 80 }
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :primary_color, format: { with: /\A#\h{6}\z/, message: "must be a hex colour like #6c7bff" }
  validates :logo_url, format: { with: %r{\Ahttps?://\S+\z}, message: "must start with http:// or https://" }, allow_blank: true

  def self.instance
    first_or_create!(site_name: "My Site")
  end
end
