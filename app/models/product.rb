class Product < ApplicationRecord
  belongs_to :vendor, optional: true

  validates :name, presence: true
  validates :sku, uniqueness: true, allow_blank: true
  validates :current_stock, numericality: { greater_than_or_equal_to: 0 }
end
