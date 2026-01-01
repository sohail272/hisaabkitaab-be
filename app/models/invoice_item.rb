class InvoiceItem < ApplicationRecord
  belongs_to :invoice
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }

  before_save :calculate_totals

  private

  def calculate_totals
    tax_pct = tax_percent || 0
    base_total = unit_price * quantity
    self.tax_amount = (base_total * tax_pct / 100.0).round(2)
    self.line_total = (base_total + tax_amount).round(2)
  end
end
