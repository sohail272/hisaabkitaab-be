class AddStoreIdToPurchases < ActiveRecord::Migration[7.1]
  def change
    add_reference :purchases, :store, null: true, foreign_key: true
  end
end

