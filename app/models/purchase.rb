class Purchase < ApplicationRecord
  belongs_to :vendor
  has_many :purchase_items, dependent: :destroy
  has_many :purchase_payments, dependent: :destroy
  has_many :stock_movements, dependent: :destroy

  accepts_nested_attributes_for :purchase_items, allow_destroy: true

  enum status: { draft: 0, finalized: 1, cancelled: 2 }, _default: :finalized

  before_validation :generate_purchase_no, on: :create
  before_validation :set_purchased_at, on: :create
  after_commit :calculate_purchase_totals, on: :create
  after_commit :increase_stock, on: :create
  after_save :recalculate_totals, if: :saved_change_to_discount_total?

  def paid_total
    purchase_payments.sum(:amount) || 0
  end

  def balance_due
    grand_total.to_f - paid_total
  end

  def recalculate_totals!
    reload
    
    # Calculate totals from purchase_items
    items_subtotal = purchase_items.sum { |item| (item.unit_price * item.quantity) }
    items_tax_total = purchase_items.sum(:tax_amount)
    items_line_total = purchase_items.sum(:line_total)
    
    # Subtotal is the sum of line totals minus tax (base amount)
    self.subtotal = items_line_total - items_tax_total
    self.tax_total = items_tax_total
    self.grand_total = subtotal + tax_total - (discount_total || 0)
    
    # Use update_columns to avoid triggering callbacks
    update_columns(
      subtotal: subtotal,
      tax_total: tax_total,
      grand_total: grand_total
    )
  end

  private

  def calculate_purchase_totals
    recalculate_totals!
  end

  def generate_purchase_no
    return if purchase_no.present?

    date_part = Time.zone.today.strftime("%Y%m%d")
    prefix = "PUR-#{date_part}-"

    last_no = Purchase
      .where("purchase_no LIKE ?", "#{prefix}%")
      .order(purchase_no: :desc)
      .limit(1)
      .pluck(:purchase_no)
      .first

    seq = last_no.present? ? last_no.split("-").last.to_i + 1 : 1
    self.purchase_no = "#{prefix}#{seq.to_s.rjust(4, '0')}"
  end

  def set_purchased_at
    self.purchased_at = Time.current if finalized? && purchased_at.nil?
  end

  def recalculate_totals
    recalculate_totals!
  end

  def increase_stock
    return unless finalized?
    
    reload
    
    purchase_items.each do |item|
      product = item.product.reload
      old_stock = product.current_stock
      old_price = product.purchase_price.to_f
      new_price = item.unit_price.to_f
      new_quantity = item.quantity
      
      # Calculate average price if prices differ
      if old_stock > 0 && old_price != new_price && new_price > 0
        # Average price = (old_stock * old_price + new_quantity * new_price) / (old_stock + new_quantity)
        total_value = (old_stock * old_price) + (new_quantity * new_price)
        total_stock = old_stock + new_quantity
        average_price = (total_value / total_stock).round(2)
        
        # Update product purchase price to average
        product.update_column(:purchase_price, average_price)
      elsif old_stock == 0 || old_price == 0
        # If no existing stock or price is 0, use new price
        product.update_column(:purchase_price, new_price) if new_price > 0
      end
      
      # Increase stock
      product.increment!(:current_stock, new_quantity)

      # Create stock movement record
      StockMovement.create!(
        product: product,
        purchase: self,
        movement_type: :in,
        quantity: new_quantity,
        occurred_at: Time.current
      )
    end
  end
end
