class CreatePurchases < ActiveRecord::Migration[7.1]
  def change
    create_table :purchases do |t|
      t.references :vendor, null: false, foreign_key: true

      t.string :purchase_no, null: false

      t.decimal :subtotal,       precision: 12, scale: 2, default: 0, null: false
      t.decimal :tax_total,      precision: 12, scale: 2, default: 0, null: false
      t.decimal :discount_total, precision: 12, scale: 2, default: 0, null: false
      t.decimal :grand_total,    precision: 12, scale: 2, default: 0, null: false

      t.integer :status, default: 0, null: false # draft
      t.datetime :purchased_at
      t.text :note

      t.timestamps
    end

    add_index :purchases, :purchase_no, unique: true
    add_index :purchases, :status
    add_index :purchases, :purchased_at
  end
end
