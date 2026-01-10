class Store < ApplicationRecord
  belongs_to :organization
  has_many :users, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :vendors, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :purchases, dependent: :destroy
  has_many :stock_movements, dependent: :destroy

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
end

