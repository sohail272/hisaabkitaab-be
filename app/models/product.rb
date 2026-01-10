class Product < ApplicationRecord
  belongs_to :store, optional: true
  belongs_to :vendor, optional: true

  validates :name, presence: true
  validates :sku, uniqueness: { scope: :store_id }, allow_blank: true
  validates :current_stock, numericality: { greater_than_or_equal_to: 0 }
end
