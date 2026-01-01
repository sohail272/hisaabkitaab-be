# HisaabKitaab Backend API

**HisaabKitaab** (हिसाब-किताब) is a comprehensive inventory and billing management system. This is the Rails API backend that powers the React frontend.

## 📋 Overview

HisaabKitaab provides a complete solution for managing:
- **Products** - Inventory management with stock tracking
- **Vendors** - Supplier management
- **Customers** - Customer relationship management
- **Purchases** - Purchase orders and stock intake
- **Invoices** - Sales invoicing and billing
- **Stock Movements** - Automatic stock tracking (IN/OUT)
- **Dashboard** - Business analytics and insights

## 🛠️ Tech Stack

- **Ruby**: 3.1.2
- **Rails**: 7.1.6
- **Database**: PostgreSQL
- **API**: RESTful JSON API
- **Server**: Puma
- **CORS**: rack-cors

## 🚀 Getting Started

### Prerequisites

- Ruby 3.1.2 (use [rbenv](https://github.com/rbenv/rbenv) or [rvm](https://rvm.io/))
- PostgreSQL 9.3+
- Bundler gem

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd hisaabkitaab-be
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Setup database**
   ```bash
   # Create databases
   rails db:create
   
   # Run migrations
   rails db:migrate
   
   # (Optional) Seed sample data
   rails db:seed
   ```

4. **Start the server**
   ```bash
   rails server
   ```

   The API will be available at `http://localhost:3000`

## 📁 Project Structure

```
hisaabkitaab-be/
├── app/
│   ├── controllers/
│   │   └── api/v1/          # API controllers
│   │       ├── dashboard_controller.rb
│   │       ├── products_controller.rb
│   │       ├── vendors_controller.rb
│   │       ├── customers_controller.rb
│   │       ├── invoices_controller.rb
│   │       └── purchases_controller.rb
│   ├── models/              # ActiveRecord models
│   │   ├── product.rb
│   │   ├── vendor.rb
│   │   ├── customer.rb
│   │   ├── purchase.rb
│   │   ├── purchase_item.rb
│   │   ├── purchase_payment.rb
│   │   ├── invoice.rb
│   │   ├── invoice_item.rb
│   │   └── stock_movement.rb
│   └── ...
├── config/
│   ├── routes.rb            # API routes
│   ├── database.yml         # Database configuration
│   ├── cors.rb              # CORS settings
│   └── ...
├── db/
│   ├── migrate/            # Database migrations
│   └── schema.rb           # Database schema
└── ...
```

## 🔌 API Endpoints

All endpoints are prefixed with `/api/v1`

### Dashboard
- `GET /api/v1/dashboard` - Get dashboard statistics and recent data

### Products
- `GET /api/v1/products` - List all products
- `GET /api/v1/products/:id` - Get product details
- `POST /api/v1/products` - Create new product
- `PUT /api/v1/products/:id` - Update product
- `DELETE /api/v1/products/:id` - Delete product

### Vendors
- `GET /api/v1/vendors` - List all vendors
- `GET /api/v1/vendors/:id` - Get vendor details
- `POST /api/v1/vendors` - Create new vendor
- `PUT /api/v1/vendors/:id` - Update vendor
- `DELETE /api/v1/vendors/:id` - Delete vendor

### Customers
- `GET /api/v1/customers` - List all customers (supports `?query=` parameter)
- `GET /api/v1/customers/:id` - Get customer details
- `GET /api/v1/customers/find_by_phone` - Find customer by phone number
- `POST /api/v1/customers` - Create new customer
- `PUT /api/v1/customers/:id` - Update customer
- `DELETE /api/v1/customers/:id` - Delete customer

### Invoices
- `GET /api/v1/invoices` - List all invoices
- `GET /api/v1/invoices/:id` - Get invoice details
- `POST /api/v1/invoices` - Create new invoice (auto-finalized, reduces stock)
- `PUT /api/v1/invoices/:id` - Update invoice
- `DELETE /api/v1/invoices/:id` - Delete invoice

### Purchases
- `GET /api/v1/purchases` - List all purchases
- `GET /api/v1/purchases/:id` - Get purchase details
- `POST /api/v1/purchases` - Create new purchase (auto-finalized, increases stock)
- `PUT /api/v1/purchases/:id` - Update purchase
- `DELETE /api/v1/purchases/:id` - Delete purchase
- `POST /api/v1/purchases/:id/add_payment` - Add payment to purchase

## 📊 Data Models

### Product
- Manages inventory items
- Tracks: name, SKU, barcode, purchase_price, selling_price, current_stock
- Belongs to: Vendor (optional)
- Has many: PurchaseItems, InvoiceItems, StockMovements

### Vendor
- Supplier information
- Tracks: name, phone, email, address, active status
- Has many: Purchases, Products

### Customer
- Customer information
- Tracks: name, phone, email, address, active status
- Phone number must be unique
- Has many: Invoices

### Purchase
- Purchase orders from vendors
- Auto-finalized on creation (stock increases automatically)
- Tracks: vendor, purchase_no, subtotal, tax_total, grand_total, status
- Has many: PurchaseItems, PurchasePayments
- Calculates: paid_total, balance_due

### Invoice
- Sales invoices to customers
- Auto-finalized on creation (stock decreases automatically)
- Tracks: customer, invoice_no, subtotal, tax_total, discount_total, roundoff, grand_total, payment_method, status
- Has many: InvoiceItems
- Auto-generates invoice number: `INV-YYYYMMDD-0001`

### StockMovement
- Audit trail for stock changes
- Tracks: product, quantity, movement_type (in/out), source (purchase/invoice)
- Automatically created when purchases/invoices are finalized

## 🔧 Configuration

### Database

Database names:
- Development: `hisaabkitaab_be_development`
- Test: `hisaabkitaab_be_test`
- Production: `hisaabkitaab_be_production`

Update `config/database.yml` if needed.

### CORS

CORS is configured in `config/initializers/cors.rb` to allow requests from the frontend.

### Environment Variables

For production, set:
- `HISAABKITAAB_BE_DATABASE_PASSWORD` - Database password
- `RAILS_MAX_THREADS` - Puma thread count (default: 5)
- `REDIS_URL` - Redis URL for Action Cable (if used)

## 🧪 Testing

```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/product_test.rb
```

## 📝 Key Features

### Automatic Stock Management
- **Stock IN**: When a purchase is created, stock automatically increases
- **Stock OUT**: When an invoice is created, stock automatically decreases
- **Stock Movements**: All stock changes are tracked in StockMovement records

### Invoice Numbering
- Format: `INV-YYYYMMDD-0001`
- Auto-increments per day
- Example: `INV-20260101-0001`, `INV-20260101-0002`, etc.

### Purchase Numbering
- Format: `PUR-YYYYMMDD-0001`
- Auto-increments per day

### Customer Management
- Phone number uniqueness enforced
- Auto-find or create customers by phone number
- Supports search by name, phone, or email

### Payment Tracking
- Purchases support partial payments
- Tracks: paid_total, balance_due
- Multiple payment methods supported

### Invoice Features
- Discount calculation (percentage or fixed amount)
- Roundoff support for percentage discounts
- Multiple payment methods (cash, card, purchase order, etc.)
- Date selection (supports backdating)

## 🚢 Deployment

### Production Setup

1. Set environment variables
2. Configure database credentials
3. Run migrations: `rails db:migrate RAILS_ENV=production`
4. Precompile assets (if any): `rails assets:precompile`
5. Start server with Puma

### Docker

A `Dockerfile` is included for containerized deployment.

## 📚 API Request/Response Format

### Request Format
All requests use JSON:
```json
{
  "product": {
    "name": "Product Name",
    "sku": "SKU123",
    "purchase_price": "100.00",
    "selling_price": "150.00"
  }
}
```

### Response Format
All responses are JSON:
```json
{
  "id": 1,
  "name": "Product Name",
  "sku": "SKU123",
  "current_stock": 50,
  ...
}
```

## 🔐 Security Notes

- CORS is configured for frontend access
- Database credentials should be set via environment variables
- No authentication implemented (add as needed for production)

## 📖 Documentation

For detailed architecture and API documentation, see:
- `ARCHITECTURE.md` (in frontend repository)
- API endpoints are self-documenting via Rails routes

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Run tests
4. Submit a pull request

## 📄 License

[Add your license here]

## 👥 Support

For issues or questions, please open an issue in the repository.

---

**HisaabKitaab** - Your complete inventory and billing solution (हिसाब-किताब)
