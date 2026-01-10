class Organization < ApplicationRecord
  has_many :stores, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :products, through: :stores
  has_many :vendors, through: :stores
  has_many :customers, through: :stores
  has_many :invoices, through: :stores
  has_many :purchases, through: :stores

  validates :name, presence: true
end

