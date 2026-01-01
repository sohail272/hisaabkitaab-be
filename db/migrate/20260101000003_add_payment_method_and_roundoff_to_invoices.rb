class AddPaymentMethodAndRoundoffToInvoices < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :payment_method, :string
    add_column :invoices, :roundoff, :decimal, precision: 12, scale: 2, default: 0.0, null: false
  end
end

