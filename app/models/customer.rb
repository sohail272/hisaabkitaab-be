class Customer < ApplicationRecord
  has_many :invoices, dependent: :restrict_with_error
  validates :name, presence: true
  validates :phone, presence: true
end

