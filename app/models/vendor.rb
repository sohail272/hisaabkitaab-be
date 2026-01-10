class Vendor < ApplicationRecord
  belongs_to :store, optional: true
  has_many :purchases, dependent: :restrict_with_error
  has_many :products, dependent: :restrict_with_error
  validates :name, presence: true
  validates :name, uniqueness: { scope: :store_id, message: "A vendor with this name already exists in this store" }
end
