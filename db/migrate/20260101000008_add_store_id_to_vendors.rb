class AddStoreIdToVendors < ActiveRecord::Migration[7.1]
  def change
    add_reference :vendors, :store, null: true, foreign_key: true
  end
end

