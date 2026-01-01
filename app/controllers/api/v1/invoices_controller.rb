class Api::V1::InvoicesController < ApplicationController
  def index
    invoices = Invoice.includes(:customer, :invoice_items => :product).order(created_at: :desc).limit(200)
    render json: invoices.as_json(include: { customer: {}, invoice_items: { include: :product } })
  end

  def show
    invoice = Invoice.includes(:customer, :invoice_items => :product).find(params[:id])
    render json: invoice.as_json(include: { customer: {}, invoice_items: { include: :product } })
  end

  def create
    # Handle customer creation/finding if customer_id not provided
    invoice_params_hash = invoice_params.to_h
    
    # Remove update_customer_name from invoice params (it's not an invoice attribute)
    invoice_params_hash.delete(:update_customer_name)
    
    unless invoice_params_hash[:customer_id].present?
      customer = find_or_create_customer
      invoice_params_hash[:customer_id] = customer.id if customer
    end
    
    invoice = Invoice.create!(invoice_params_hash)
    # Stock is automatically reduced via after_create callback
    render json: invoice.reload.as_json(include: { customer: {} }), status: :created
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    invoice = Invoice.find(params[:id])
    invoice_params_hash = invoice_params.to_h
    
    # Remove update_customer_name from invoice params (it's not an invoice attribute)
    invoice_params_hash.delete(:update_customer_name)
    
    # Handle customer creation/finding if customer_id not provided
    unless invoice_params_hash[:customer_id].present?
      customer = find_or_create_customer
      invoice_params_hash[:customer_id] = customer.id if customer
    end
    
    invoice.update!(invoice_params_hash)
    invoice.recalculate_totals! if invoice_params_hash[:discount_total] || invoice_params_hash[:roundoff] || invoice_params_hash[:invoice_items_attributes]
    render json: invoice.reload.as_json(include: { customer: {}, invoice_items: { include: :product } })
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    invoice = Invoice.find(params[:id])
    invoice.destroy!
    head :no_content
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def find_or_create_customer
    name = params.dig(:invoice, :customer_name)&.strip
    phone = params.dig(:invoice, :customer_phone)&.strip
    update_name_param = params.dig(:invoice, :update_customer_name)
    update_name = update_name_param == true || update_name_param == "true" || update_name_param == true.to_s
    
    # Name and phone are required
    if name.blank? || phone.blank?
      raise "Customer name and phone number are required"
    end
    
    # Try to find existing customer by phone
    customer = Customer.where(phone: phone).first
    if customer
      # Update name only if explicitly requested
      if update_name && customer.name != name
        customer.update(name: name)
      end
      return customer
    end
    
    # Create new customer
    Customer.create!(
      name: name,
      phone: phone,
      active: true
    )
  end

  def invoice_params
		params.require(:invoice).permit(
			:customer_id,
			:customer_name,
			:customer_phone,
			:update_customer_name,
			:discount_total,
			:roundoff,
			:payment_method,
			:status,
			:billed_at,
			invoice_items_attributes: [
				:id,
				:product_id,
				:quantity,
				:unit_price,
				:tax_percent,
				:_destroy
			]
		)
	end
end