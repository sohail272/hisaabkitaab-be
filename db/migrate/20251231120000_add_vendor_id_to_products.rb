class AddVendorIdToProducts < ActiveRecord::Migration[7.1]
  def change
    add_reference :products, :vendor, null: true, foreign_key: true
  end
end

