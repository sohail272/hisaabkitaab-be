class CreateVendors < ActiveRecord::Migration[7.1]
  def change
    create_table :vendors do |t|
      t.string :name
      t.string :phone
      t.string :email
      t.text :address
      t.boolean :active, default: true, null: false

      t.timestamps
    end
  end
end
