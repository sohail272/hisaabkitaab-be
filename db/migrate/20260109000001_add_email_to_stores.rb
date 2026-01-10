class AddEmailToStores < ActiveRecord::Migration[7.1]
  def change
    add_column :stores, :email, :string
  end
end

