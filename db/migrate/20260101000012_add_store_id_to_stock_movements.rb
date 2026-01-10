class AddStoreIdToStockMovements < ActiveRecord::Migration[7.1]
  def change
    add_reference :stock_movements, :store, null: true, foreign_key: true
  end
end

