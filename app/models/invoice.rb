class Invoice < ApplicationRecord
  belongs_to :customer, optional: true
  has_many :invoice_items, dependent: :destroy
  has_many :stock_movements, dependent: :destroy
  accepts_nested_attributes_for :invoice_items, allow_destroy: true

  enum status: { draft: 0, finalized: 1 }, _default: :finalized

  before_validation :generate_invoice_no, on: :create
  before_validation :set_billed_at, on: :create
  before_validation :populate_customer_fields, on: :create
  after_save :recalculate_totals, if: :saved_change_to_discount_total?
  after_commit :finalize_invoice, on: :create

  def recalculate_totals!
    reload # Ensure invoice_items are loaded
    
    # Calculate totals from invoice_items
    items_subtotal = invoice_items.sum { |item| (item.unit_price * item.quantity) }
    items_tax_total = invoice_items.sum(:tax_amount)
    items_line_total = invoice_items.sum(:line_total)
    
    # Subtotal is the sum of line totals minus tax (base amount)
    self.subtotal = items_line_total - items_tax_total
    self.tax_total = items_tax_total
    base_total = subtotal + tax_total - (discount_total || 0)
    # Apply roundoff if present
    self.grand_total = base_total + (roundoff || 0)
    
    # Use update_columns to avoid triggering callbacks
    update_columns(
      subtotal: subtotal,
      tax_total: tax_total,
      grand_total: grand_total
    )
  end

  private

  def recalculate_totals
    recalculate_totals!
  end

  def finalize_invoice
    # Calculate totals first
    recalculate_totals!
    # Then reduce stock
    reduce_stock
  end

  def generate_invoice_no
    return if invoice_no.present?

    date_part = Time.zone.today.strftime("%Y%m%d")
    prefix = "INV-#{date_part}-"

    last_no = Invoice
      .where("invoice_no LIKE ?", "#{prefix}%")
      .order(invoice_no: :desc)
      .limit(1)
      .pluck(:invoice_no)
      .first

    seq = last_no.present? ? last_no.split("-").last.to_i + 1 : 1
    self.invoice_no = "#{prefix}#{seq.to_s.rjust(4, '0')}"
  end

  def set_billed_at
    self.billed_at = Time.current if finalized? && billed_at.nil?
  end

  def populate_customer_fields
    return unless has_attribute?(:customer_id) && self.customer_id.present?
    
    cust = customer
    if cust.present?
      self.customer_name ||= cust.name
      self.customer_phone ||= cust.phone
    end
  end

  def reduce_stock
    return unless finalized?
    
    # Reload to ensure invoice_items are loaded
    reload
    
    invoice_items.each do |item|
      product = item.product.reload
      
      # Check stock availability
      if product.current_stock < item.quantity
        raise "Insufficient stock for #{product.name}. Available: #{product.current_stock}, Required: #{item.quantity}"
      end

      # Reduce stock
      product.decrement!(:current_stock, item.quantity)

      # Create stock movement record
      StockMovement.create!(
        product: product,
        invoice: self,
        movement_type: :out,
        quantity: item.quantity,
        occurred_at: Time.current
      )
    end
  end
end