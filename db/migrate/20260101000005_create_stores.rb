class CreateStores < ActiveRecord::Migration[7.1]
  def change
    create_table :stores do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :code, null: false
      t.text :address
      t.string :phone
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :stores, :code, unique: true
    add_index :stores, :active
  end
end

