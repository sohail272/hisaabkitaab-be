class Api::V1::DashboardController < ApplicationController
  def index
    today = Date.current
    today_start = today.beginning_of_day
    today_end = today.end_of_day

    # Today's sales
    today_invoices = Invoice.where(billed_at: today_start..today_end)
                            .where(status: :finalized)
    today_sales_count = today_invoices.count
    today_sales_total = today_invoices.sum(:grand_total)

    # Latest invoice
    latest_invoice = Invoice.includes(:invoice_items)
                           .where(status: :finalized)
                           .order(billed_at: :desc)
                           .first

    # Recent invoices for listing
    recent_invoices = Invoice.where(status: :finalized)
                            .order(Arel.sql("COALESCE(billed_at, created_at) DESC"))
                            .limit(3)

    # Recent customers (from recent invoices)
    recent_customers = Invoice.where(status: :finalized)
                             .where.not(customer_name: [nil, ""])
                             .select("customer_name, customer_phone, MAX(billed_at) as last_purchase")
                             .group(:customer_name, :customer_phone)
                             .order("MAX(billed_at) DESC")
                             .limit(5)
                             .map do |inv|
                               {
                                 name: inv.customer_name,
                                 phone: inv.customer_phone,
                                 last_purchase: inv.last_purchase
                               }
                             end

    # Low stock products
    low_stock_products = Product.where(active: true)
                                .where("current_stock < ?", 10)
                                .order(:current_stock)
                                .limit(5)

    # Recent purchases
    recent_purchases = Purchase.includes(:vendor)
                              .where(status: :finalized)
                              .order(purchased_at: :desc)
                              .limit(5)

    # Outstanding payments (purchases with balance due)
    outstanding_purchases = Purchase.includes(:purchase_payments)
                                    .where(status: :finalized)
                                    .limit(20)
                                    .select { |p| p.balance_due > 0 }
                                    .first(5)

    # Total counts
    total_products = Product.where(active: true).count
    total_vendors = Vendor.where(active: true).count
    total_invoices = Invoice.where(status: :finalized).count
    total_purchases = Purchase.where(status: :finalized).count

    # This month's sales
    month_start = today.beginning_of_month
    month_invoices = Invoice.where(billed_at: month_start..today_end)
                           .where(status: :finalized)
    month_sales_total = month_invoices.sum(:grand_total)

    render json: {
      today_sales: {
        count: today_sales_count,
        total: today_sales_total.to_f
      },
      month_sales: {
        total: month_sales_total.to_f
      },
      latest_invoice: latest_invoice ? {
        id: latest_invoice.id,
        invoice_no: latest_invoice.invoice_no,
        customer_name: latest_invoice.customer_name,
        customer_phone: latest_invoice.customer_phone,
        grand_total: latest_invoice.grand_total.to_f,
        billed_at: latest_invoice.billed_at
      } : nil,
      recent_invoices: recent_invoices.map do |inv|
        {
          id: inv.id,
          invoice_no: inv.invoice_no,
          customer_name: inv.customer_name,
          customer_phone: inv.customer_phone,
          grand_total: inv.grand_total.to_f,
          billed_at: inv.billed_at,
          created_at: inv.created_at
        }
      end,
      recent_customers: recent_customers,
      low_stock_products: low_stock_products.map do |p|
        {
          id: p.id,
          name: p.name,
          current_stock: p.current_stock,
          sku: p.sku
        }
      end,
      recent_purchases: recent_purchases.map do |p|
        {
          id: p.id,
          purchase_no: p.purchase_no,
          vendor_name: p.vendor&.name,
          grand_total: p.grand_total.to_f,
          purchased_at: p.purchased_at
        }
      end,
      outstanding_purchases: outstanding_purchases.map do |p|
        paid = p.paid_total.to_f
        {
          id: p.id,
          purchase_no: p.purchase_no,
          grand_total: p.grand_total.to_f,
          paid_total: paid,
          balance_due: (p.grand_total.to_f - paid)
        }
      end,
      totals: {
        products: total_products,
        vendors: total_vendors,
        invoices: total_invoices,
        purchases: total_purchases
      }
    }
  end
end

