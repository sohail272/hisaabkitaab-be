# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "🌱 Starting seed data creation..."

# Skip if organization already exists (for production safety)
if Organization.any?
  puts "⚠️  Organization already exists. Skipping seed data to avoid duplicates."
  puts "   If you want to create test data, delete existing data first."
  exit
end

ActiveRecord::Base.transaction do
  # Create Organization
  puts "\n📋 Creating Organization..."
  organization = Organization.create!(
    name: "SMK Clothing",
    phone: "+1-555-0100",
    email: "contact@smkclothing.com",
    address: "123 Fashion Street, New York, NY 10001",
    active: true
  )
  puts "✅ Created Organization: #{organization.name} (ID: #{organization.id})"

  # Create Stores
  puts "\n🏪 Creating Stores..."
  store1 = Store.create!(
    organization: organization,
    name: "SMK Clothing - Downtown Branch",
    code: "SMK-DT-001",
    address: "456 Main Street, Downtown, NY 10002",
    phone: "+1-555-0201",
    active: true
  )
  puts "✅ Created Store: #{store1.name} (Code: #{store1.code})"

  store2 = Store.create!(
    organization: organization,
    name: "SMK Clothing - Uptown Branch",
    code: "SMK-UP-001",
    address: "789 Broadway, Uptown, NY 10003",
    phone: "+1-555-0202",
    active: true
  )
  puts "✅ Created Store: #{store2.name} (Code: #{store2.code})"

  # Create Users
  puts "\n👤 Creating Users..."

  # Organization Admin (can access all stores)
  org_admin = User.create!(
    organization: organization,
    store: nil, # Org admins don't belong to a specific store
    name: "Admin User",
    email: "admin@smkclothing.com",
    password: "admin123",
    phone: "+1-555-1001",
    role: "org_admin",
    active: true
  )
  puts "✅ Created Org Admin: #{org_admin.name} (#{org_admin.email}) - Password: admin123"

  # Store Manager for Downtown Branch
  store_manager1 = User.create!(
    organization: organization,
    store: store1,
    name: "Downtown Manager",
    email: "manager.dt@smkclothing.com",
    password: "manager123",
    phone: "+1-555-2001",
    role: "store_manager",
    active: true
  )
  puts "✅ Created Store Manager: #{store_manager1.name} (#{store_manager1.email}) - Password: manager123"

  # Store Manager for Uptown Branch
  store_manager2 = User.create!(
    organization: organization,
    store: store2,
    name: "Uptown Manager",
    email: "manager.up@smkclothing.com",
    password: "manager123",
    phone: "+1-555-2002",
    role: "store_manager",
    active: true
  )
  puts "✅ Created Store Manager: #{store_manager2.name} (#{store_manager2.email}) - Password: manager123"

  # Store Workers (can only create invoices)
  store_worker1 = User.create!(
    organization: organization,
    store: store1,
    name: "Downtown Worker",
    email: "worker.dt@smkclothing.com",
    password: "worker123",
    phone: "+1-555-3001",
    role: "store_worker",
    active: true
  )
  puts "✅ Created Store Worker: #{store_worker1.name} (#{store_worker1.email}) - Password: worker123"

  store_worker2 = User.create!(
    organization: organization,
    store: store2,
    name: "Uptown Worker",
    email: "worker.up@smkclothing.com",
    password: "worker123",
    phone: "+1-555-3002",
    role: "store_worker",
    active: true
  )
  puts "✅ Created Store Worker: #{store_worker2.name} (#{store_worker2.email}) - Password: worker123"

  # Create Sample Vendors for Downtown Store
  puts "\n🏢 Creating Vendors for Downtown Store..."
  vendor1_dt = Vendor.create!(
    store: store1,
    name: "Fashion Wholesale Inc.",
    phone: "+1-555-4001",
    email: "sales@fashionwholesale.com",
    address: "100 Supplier Lane, NY",
    active: true
  )
  puts "✅ Created Vendor: #{vendor1_dt.name}"

  vendor2_dt = Vendor.create!(
    store: store1,
    name: "Textile Suppliers LLC",
    phone: "+1-555-4002",
    email: "info@textilesuppliers.com",
    address: "200 Material Street, NY",
    active: true
  )
  puts "✅ Created Vendor: #{vendor2_dt.name}"

  # Create Sample Vendors for Uptown Store
  puts "\n🏢 Creating Vendors for Uptown Store..."
  vendor1_up = Vendor.create!(
    store: store2,
    name: "Premium Fashion Co.",
    phone: "+1-555-4003",
    email: "contact@premiumfashion.com",
    address: "300 Designer Ave, NY",
    active: true
  )
  puts "✅ Created Vendor: #{vendor1_up.name}"

  # Create Sample Products for Downtown Store
  puts "\n📦 Creating Products for Downtown Store..."
  products_dt = [
    { name: "Men's T-Shirt", sku: "TEE-M-001", barcode: "1234567890123", purchase_price: 15.00, selling_price: 25.00, current_stock: 50, vendor: vendor1_dt },
    { name: "Women's Jeans", sku: "JNS-W-001", barcode: "1234567890124", purchase_price: 35.00, selling_price: 65.00, current_stock: 30, vendor: vendor1_dt },
    { name: "Unisex Hoodie", sku: "HDI-U-001", barcode: "1234567890125", purchase_price: 45.00, selling_price: 85.00, current_stock: 20, vendor: vendor2_dt },
    { name: "Men's Dress Shirt", sku: "SHR-M-001", barcode: "1234567890126", purchase_price: 40.00, selling_price: 75.00, current_stock: 25, vendor: vendor1_dt },
    { name: "Women's Skirt", sku: "SKT-W-001", barcode: "1234567890127", purchase_price: 20.00, selling_price: 40.00, current_stock: 35, vendor: vendor2_dt }
  ]

  products_dt.each do |product_attrs|
    vendor = product_attrs.delete(:vendor)
    product = Product.create!(product_attrs.merge(store: store1, vendor: vendor, active: true))
    puts "✅ Created Product: #{product.name} (Stock: #{product.current_stock})"
  end

  # Create Sample Products for Uptown Store
  puts "\n📦 Creating Products for Uptown Store..."
  products_up = [
    { name: "Designer T-Shirt", sku: "TEE-D-001", barcode: "2234567890123", purchase_price: 25.00, selling_price: 50.00, current_stock: 40, vendor: vendor1_up },
    { name: "Premium Jeans", sku: "JNS-P-001", barcode: "2234567890124", purchase_price: 50.00, selling_price: 95.00, current_stock: 25, vendor: vendor1_up },
    { name: "Luxury Hoodie", sku: "HDI-L-001", barcode: "2234567890125", purchase_price: 65.00, selling_price: 125.00, current_stock: 15, vendor: vendor1_up }
  ]

  products_up.each do |product_attrs|
    vendor = product_attrs.delete(:vendor)
    product = Product.create!(product_attrs.merge(store: store2, vendor: vendor, active: true))
    puts "✅ Created Product: #{product.name} (Stock: #{product.current_stock})"
  end

  # Create Sample Customers (shared across stores)
  puts "\n👥 Creating Customers..."
  customers = [
    { name: "John Doe", phone: "+1-555-5001", email: "john@example.com", address: "123 Customer St, NY", store: store1 },
    { name: "Jane Smith", phone: "+1-555-5002", email: "jane@example.com", address: "456 Buyer Ave, NY", store: store1 },
    { name: "Bob Johnson", phone: "+1-555-5003", email: "bob@example.com", address: "789 Shopper Rd, NY", store: store2 },
    { name: "Alice Williams", phone: "+1-555-5004", email: "alice@example.com", address: "321 Client Lane, NY", store: store2 }
  ]

  customers.each do |customer_attrs|
    customer = Customer.create!(customer_attrs.merge(active: true))
    puts "✅ Created Customer: #{customer.name} (#{customer.phone})"
  end

  puts "\n✨ Seed data created successfully!"
  puts "\n📝 Test User Credentials:"
  puts "   Org Admin:     admin@smkclothing.com / admin123"
  puts "   Store Manager: manager.dt@smkclothing.com / manager123 (Downtown)"
  puts "   Store Manager: manager.up@smkclothing.com / manager123 (Uptown)"
  puts "   Store Worker:  worker.dt@smkclothing.com / worker123 (Downtown)"
  puts "   Store Worker:  worker.up@smkclothing.com / worker123 (Uptown)"
  puts "\n🏪 Store Codes:"
  puts "   Downtown: SMK-DT-001"
  puts "   Uptown:   SMK-UP-001"
end

puts "\n✅ Seed complete!"
