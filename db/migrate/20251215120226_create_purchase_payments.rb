class CreatePurchasePayments < ActiveRecord::Migration[7.1]
  def change
    create_table :purchase_payments do |t|
      t.references :purchase, null: false, foreign_key: true
      t.decimal :amount
      t.string :payment_method
      t.datetime :paid_at
      t.string :note

      t.timestamps
    end
  end
end
