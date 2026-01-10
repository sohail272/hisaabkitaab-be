class Api::V1::PurchasesController < ApplicationController
  def index
    purchases = scope_by_store(Purchase).includes(:vendor, :purchase_items => :product)
                       .order(created_at: :desc)
                       .limit(200)
    render json: purchases.as_json(
      include: {
        vendor: {},
        purchase_items: { include: :product }
      },
      methods: [:paid_total, :balance_due]
    )
  end

  def show
    purchase = scope_by_store(Purchase).includes(:vendor, { purchase_items: :product }, :purchase_payments)
                       .find(params[:id])
    render json: purchase.as_json(
      include: {
        vendor: {},
        purchase_items: { include: :product },
        purchase_payments: {}
      },
      methods: [:paid_total, :balance_due]
    )
  end

  def create
    # Set store_id based on user's store or selected store (for org admin)
    # Check purchase_params first, then params, then current_user.store_id
    purchase_params_hash = purchase_params.to_h
    store_id = purchase_params_hash[:store_id] || params[:store_id] || current_user.store_id
    
    # For org admin, store_id must be provided or use default
    if current_user.org_admin? && !store_id
      render json: { error: 'store_id is required for organization admins' }, status: :bad_request
      return
    end

    purchase_params_hash[:store_id] = store_id
    
    purchase = Purchase.create!(purchase_params_hash)
    
    # Create payment if provided
    payment = get_payment_params
    if payment[:amount].present? && payment[:amount].to_f > 0
      purchase.purchase_payments.create!(payment)
    end
    
    # Stock is automatically increased via after_commit callback
    render json: purchase.reload.as_json(
      include: {
        vendor: {},
        purchase_items: { include: :product },
        purchase_payments: {}
      },
      methods: [:paid_total, :balance_due]
    ), status: :created
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    purchase = scope_by_store(Purchase).find(params[:id])
    purchase.update!(purchase_params)
    
    # Update or create payment if provided
    payment = get_payment_params
    if payment[:amount].present? && payment[:amount].to_f > 0
      # If there's an existing payment, update it, otherwise create new
      existing_payment = purchase.purchase_payments.first
      if existing_payment
        existing_payment.update!(payment)
      else
        purchase.purchase_payments.create!(payment)
      end
    end
    
    render json: purchase.reload.as_json(
      include: {
        vendor: {},
        purchase_items: { include: :product },
        purchase_payments: {}
      },
      methods: [:paid_total, :balance_due]
    )
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    purchase = scope_by_store(Purchase).find(params[:id])
    purchase.destroy!
    head :no_content
  end

  def add_payment
    purchase = scope_by_store(Purchase).find(params[:id])
    payment = payment_params_for_add
    purchase.purchase_payments.create!(payment) if payment[:amount].present?
    render json: purchase.reload.as_json(
      include: {
        vendor: {},
        purchase_items: { include: :product },
        purchase_payments: {}
      },
      methods: [:paid_total, :balance_due]
    ), status: :created
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def purchase_params
    params.require(:purchase).permit(
      :vendor_id,
      :note,
      :store_id,
      purchase_items_attributes: [
        :id,
        :product_id,
        :quantity,
        :unit_price,
        :tax_percent,
        :_destroy
      ]
    )
  end

  def get_payment_params
    # Get payment from purchase hash (for create/update)
    payment_data = params.dig(:purchase, :payment)
    return {} unless payment_data && payment_data[:amount].present?
    
    {
      amount: payment_data[:amount].to_s,
      payment_method: payment_data[:payment_method] || "cash",
      note: payment_data[:note],
      paid_at: Time.current
    }
  end

  def payment_params_for_add
    # For add_payment endpoint, use purchase_payment params
    params.require(:purchase_payment).permit(
      :amount,
      :payment_method,
      :note
    ).merge(paid_at: Time.current)
  end
end

