class CreatePurchaseItems < ActiveRecord::Migration[7.1]
  def change
    create_table :purchase_items do |t|
      t.references :purchase, null: false, foreign_key: true
      t.references :product,  null: false, foreign_key: true

      t.integer :quantity, null: false, default: 1

      t.decimal :unit_price,   precision: 12, scale: 2, default: 0, null: false
      t.decimal :tax_percent,  precision: 5,  scale: 2, default: 0, null: false
      t.decimal :tax_amount,   precision: 12, scale: 2, default: 0, null: false
      t.decimal :line_total,   precision: 12, scale: 2, default: 0, null: false

      t.timestamps
    end

    add_index :purchase_items, [:purchase_id, :product_id]
  end
end
