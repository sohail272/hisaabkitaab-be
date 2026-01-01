class CreateStockMovements < ActiveRecord::Migration[7.1]
  def change
    create_table :stock_movements do |t|
      t.references :product,  null: false, foreign_key: true
      t.references :purchase, null: true,  foreign_key: true
      t.references :invoice,  null: true,  foreign_key: true

      t.integer :movement_type, null: false # in/out/adjust
      t.integer :quantity, null: false
      t.datetime :occurred_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.string :note

      t.timestamps
    end

    add_index :stock_movements, :movement_type
    add_index :stock_movements, :occurred_at
    add_index :stock_movements, [:product_id, :occurred_at]
  end
end
