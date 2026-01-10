class Api::V1::InvoicesController < ApplicationController
  def index
    invoices = scope_by_store(Invoice).includes(:customer, :store, :invoice_items => :product).order(created_at: :desc).limit(200)
    render json: invoices.map { |inv| invoice_json(inv) }
  end

  def show
    invoice = scope_by_store(Invoice).includes(:customer, :store, :invoice_items => :product).find(params[:id])
    render json: invoice_json(invoice)
  end

  def create
    # Set store_id based on user's store or selected store (for org admin)
    # Check invoice_params first, then params, then current_user.store_id
    invoice_params_hash = invoice_params.to_h
    store_id = invoice_params_hash[:store_id] || params[:store_id] || current_user.store_id
    
    # For org admin, store_id must be provided or use default
    if current_user.org_admin? && !store_id
      render json: { error: 'store_id is required for organization admins' }, status: :bad_request
      return
    end

    # Handle customer creation/finding if customer_id not provided
    # Remove update_customer_name from invoice params (it's not an invoice attribute)
    invoice_params_hash.delete(:update_customer_name)
    
    # Set store_id
    invoice_params_hash[:store_id] = store_id
    
    unless invoice_params_hash[:customer_id].present?
      customer = find_or_create_customer(store_id)
      invoice_params_hash[:customer_id] = customer.id if customer
    end
    
    invoice = Invoice.create!(invoice_params_hash)
    # Stock is automatically reduced via after_create callback
    render json: invoice_json(invoice.reload), status: :created
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    invoice = scope_by_store(Invoice).find(params[:id])
    invoice_params_hash = invoice_params.to_h
    
    # Remove update_customer_name from invoice params (it's not an invoice attribute)
    invoice_params_hash.delete(:update_customer_name)
    
    # Handle customer creation/finding if customer_id not provided
    unless invoice_params_hash[:customer_id].present?
      customer = find_or_create_customer(invoice.store_id)
      invoice_params_hash[:customer_id] = customer.id if customer
    end
    
    invoice.update!(invoice_params_hash)
    invoice.recalculate_totals! if invoice_params_hash[:discount_total] || invoice_params_hash[:roundoff] || invoice_params_hash[:invoice_items_attributes]
    render json: invoice_json(invoice.reload)
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    invoice = scope_by_store(Invoice).find(params[:id])
    invoice.destroy!
    head :no_content
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def find_or_create_customer(store_id)
    name = params.dig(:invoice, :customer_name)&.strip
    phone = params.dig(:invoice, :customer_phone)&.strip
    update_name_param = params.dig(:invoice, :update_customer_name)
    update_name = update_name_param == true || update_name_param == "true" || update_name_param == true.to_s
    
    # Name and phone are required
    if name.blank? || phone.blank?
      raise "Customer name and phone number are required"
    end
    
    # Try to find existing customer by phone within store scope
    customer = scope_by_store(Customer).where(phone: phone).first
    if customer
      # Update name only if explicitly requested
      if update_name && customer.name != name
        customer.update(name: name)
      end
      return customer
    end
    
    # Create new customer with store_id
    Customer.create!(
      name: name,
      phone: phone,
      store_id: store_id,
      active: true
    )
  end

  def invoice_json(invoice)
    json = invoice.as_json(include: { customer: {}, invoice_items: { include: :product }, store: {} })
    # Convert enum status string to numeric value
    json["status"] = Invoice.statuses[invoice.status] || invoice.read_attribute_before_type_cast(:status)
    json
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
			:store_id,
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