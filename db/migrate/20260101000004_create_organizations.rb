class CreateOrganizations < ActiveRecord::Migration[7.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :logo_url
      t.string :phone
      t.string :email
      t.text :address
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :organizations, :active
  end
end

