class Customer < ApplicationRecord
  belongs_to :store, optional: true
  has_many :invoices, dependent: :restrict_with_error
  validates :name, presence: true
  validates :phone, presence: true
  validates :phone, uniqueness: { scope: :store_id }
end