class Api::V1::CustomersController < ApplicationController
  def index
    q = params[:query].to_s.strip
    phone = params[:phone].to_s.strip
    
    # Scope by store
    scope = scope_by_store(Customer)
    
    # If phone is provided, return customer by phone (within store scope)
    if phone.present?
      customer = scope.where(phone: phone).first
      return render json: customer if customer
      return render json: nil
    end
    
    scope = scope.order(updated_at: :desc)
    
    if q.present?
      scope = scope.where(
        "name ILIKE :q OR phone ILIKE :q OR email ILIKE :q",
        q: "%#{q}%"
      )
    end
    
    render json: scope.limit(200)
  end

  def show
    customer = scope_by_store(Customer).find(params[:id])
    render json: customer
  end

  def create
    # Set store_id based on user's store or selected store (for org admin)
    store_id = params[:store_id] || customer_params[:store_id] || current_user.store_id
    
    # For org admin, store_id must be provided or use default
    if current_user.org_admin? && !store_id
      render json: { error: 'store_id is required for organization admins' }, status: :bad_request
      return
    end

    customer = Customer.new(customer_params.merge(store_id: store_id))
    
    if customer.save
      render json: customer, status: :created
    else
      render json: { error: customer.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def update
    customer = scope_by_store(Customer).find(params[:id])
    
    if customer.update(customer_params)
      render json: customer
    else
      render json: { error: customer.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def destroy
    customer = scope_by_store(Customer).find(params[:id])
    customer.destroy!
    head :no_content
  end

  def invoices
    customer = scope_by_store(Customer).find(params[:id])
    invoices = scope_by_store(Invoice).includes(:invoice_items => :product)
                      .where("customer_id = ? OR customer_phone = ?", customer.id, customer.phone)
                      .order(created_at: :desc)
                      .limit(200)
    
    render json: invoices.map { |inv| invoice_json(inv) }
  end

  private

  def customer_params
    params.require(:customer).permit(
      :name,
      :phone,
      :email,
      :address,
      :active,
      :store_id
    )
  end

  def invoice_json(invoice)
    json = invoice.as_json(include: { invoice_items: { include: :product } })
    # Convert enum status string to numeric value
    json["status"] = Invoice.statuses[invoice.status] || invoice.read_attribute_before_type_cast(:status)
    json
  end
end

