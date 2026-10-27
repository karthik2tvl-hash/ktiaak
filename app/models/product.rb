class Product < ApplicationRecord
  attribute :active, :boolean, default: true
  attribute :stock, :integer, default: 0

  before_validation { self.sku = sku.to_s.strip.upcase }

  validates :name, presence: true, length: { maximum: 120 }
  validates :sku, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :search, lambda { |q|
    next all if q.blank?
    like = "%#{sanitize_sql_like(q)}%"
    where("name LIKE :q OR sku LIKE :q OR category LIKE :q", q: like)
  }
end
