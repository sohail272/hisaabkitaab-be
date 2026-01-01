class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.string :sku
      t.string :barcode

      t.decimal :purchase_price, precision: 12, scale: 2, default: 0, null: false
      t.decimal :selling_price,  precision: 12, scale: 2, default: 0, null: false

      t.integer :current_stock, default: 0, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :products, :sku, unique: true
    add_index :products, :barcode
    add_index :products, :active
    add_index :products, :name
  end
end
