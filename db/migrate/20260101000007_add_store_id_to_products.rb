class AddStoreIdToProducts < ActiveRecord::Migration[7.1]
  def change
    add_reference :products, :store, null: true, foreign_key: true
  end
end

