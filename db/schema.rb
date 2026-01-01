# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_01_01_000003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "customers", force: :cascade do |t|
    t.string "name", null: false
    t.string "phone"
    t.string "email"
    t.text "address"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_customers_on_active"
    t.index ["phone"], name: "index_customers_on_phone"
  end

  create_table "invoice_items", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_price", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "tax_percent", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "tax_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "line_total", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id", "product_id"], name: "index_invoice_items_on_invoice_id_and_product_id"
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
    t.index ["product_id"], name: "index_invoice_items_on_product_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.string "invoice_no", null: false
    t.string "customer_name"
    t.string "customer_phone"
    t.decimal "subtotal", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "tax_total", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "discount_total", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "grand_total", precision: 12, scale: 2, default: "0.0", null: false
    t.integer "status", default: 0, null: false
    t.datetime "billed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "customer_id"
    t.string "payment_method"
    t.decimal "roundoff", precision: 12, scale: 2, default: "0.0", null: false
    t.index ["billed_at"], name: "index_invoices_on_billed_at"
    t.index ["customer_id"], name: "index_invoices_on_customer_id"
    t.index ["customer_phone"], name: "index_invoices_on_customer_phone"
    t.index ["invoice_no"], name: "index_invoices_on_invoice_no", unique: true
    t.index ["status"], name: "index_invoices_on_status"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "sku"
    t.string "barcode"
    t.decimal "purchase_price", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "selling_price", precision: 12, scale: 2, default: "0.0", null: false
    t.integer "current_stock", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "vendor_id"
    t.index ["active"], name: "index_products_on_active"
    t.index ["barcode"], name: "index_products_on_barcode"
    t.index ["name"], name: "index_products_on_name"
    t.index ["sku"], name: "index_products_on_sku", unique: true
    t.index ["vendor_id"], name: "index_products_on_vendor_id"
  end

  create_table "purchase_items", force: :cascade do |t|
    t.bigint "purchase_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_price", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "tax_percent", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "tax_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "line_total", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_purchase_items_on_product_id"
    t.index ["purchase_id", "product_id"], name: "index_purchase_items_on_purchase_id_and_product_id"
    t.index ["purchase_id"], name: "index_purchase_items_on_purchase_id"
  end

  create_table "purchase_payments", force: :cascade do |t|
    t.bigint "purchase_id", null: false
    t.decimal "amount"
    t.string "payment_method"
    t.datetime "paid_at"
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["purchase_id"], name: "index_purchase_payments_on_purchase_id"
  end

  create_table "purchases", force: :cascade do |t|
    t.bigint "vendor_id", null: false
    t.string "purchase_no", null: false
    t.decimal "subtotal", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "tax_total", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "discount_total", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "grand_total", precision: 12, scale: 2, default: "0.0", null: false
    t.integer "status", default: 0, null: false
    t.datetime "purchased_at"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["purchase_no"], name: "index_purchases_on_purchase_no", unique: true
    t.index ["purchased_at"], name: "index_purchases_on_purchased_at"
    t.index ["status"], name: "index_purchases_on_status"
    t.index ["vendor_id"], name: "index_purchases_on_vendor_id"
  end

  create_table "stock_movements", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "purchase_id"
    t.bigint "invoice_id"
    t.integer "movement_type", null: false
    t.integer "quantity", null: false
    t.datetime "occurred_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_stock_movements_on_invoice_id"
    t.index ["movement_type"], name: "index_stock_movements_on_movement_type"
    t.index ["occurred_at"], name: "index_stock_movements_on_occurred_at"
    t.index ["product_id", "occurred_at"], name: "index_stock_movements_on_product_id_and_occurred_at"
    t.index ["product_id"], name: "index_stock_movements_on_product_id"
    t.index ["purchase_id"], name: "index_stock_movements_on_purchase_id"
  end

  create_table "vendors", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.string "email"
    t.text "address"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoice_items", "products"
  add_foreign_key "invoices", "customers"
  add_foreign_key "products", "vendors"
  add_foreign_key "purchase_items", "products"
  add_foreign_key "purchase_items", "purchases"
  add_foreign_key "purchase_payments", "purchases"
  add_foreign_key "purchases", "vendors"
  add_foreign_key "stock_movements", "invoices"
  add_foreign_key "stock_movements", "products"
  add_foreign_key "stock_movements", "purchases"
end
