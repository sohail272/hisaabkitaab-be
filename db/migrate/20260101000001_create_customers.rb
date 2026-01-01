class CreateCustomers < ActiveRecord::Migration[7.1]
  def change
    create_table :customers do |t|
      t.string :name, null: false
      t.string :phone
      t.string :email
      t.text :address
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :customers, :phone
    add_index :customers, :active
  end
end

