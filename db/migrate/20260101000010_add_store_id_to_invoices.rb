class AddStoreIdToInvoices < ActiveRecord::Migration[7.1]
  def change
    add_reference :invoices, :store, null: true, foreign_key: true
  end
end

