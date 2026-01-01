class CreateInvoices < ActiveRecord::Migration[7.1]
  def change
    create_table :invoices do |t|
      t.string :invoice_no, null: false

      t.string :customer_name
      t.string :customer_phone

      t.decimal :subtotal,       precision: 12, scale: 2, default: 0, null: false
      t.decimal :tax_total,      precision: 12, scale: 2, default: 0, null: false
      t.decimal :discount_total, precision: 12, scale: 2, default: 0, null: false
      t.decimal :grand_total,    precision: 12, scale: 2, default: 0, null: false

      t.integer :status, default: 0, null: false # draft
      t.datetime :billed_at

      t.timestamps
    end

    add_index :invoices, :invoice_no, unique: true
    add_index :invoices, :status
    add_index :invoices, :billed_at
    add_index :invoices, :customer_phone
  end
end
