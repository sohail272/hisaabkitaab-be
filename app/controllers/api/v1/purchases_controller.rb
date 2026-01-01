class Api::V1::PurchasesController < ApplicationController
  def index
    purchases = Purchase.includes(:vendor, :purchase_items => :product)
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
    purchase = Purchase.includes(:vendor, { purchase_items: :product }, :purchase_payments)
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
    purchase = Purchase.create!(purchase_params)
    
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
    purchase = Purchase.find(params[:id])
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
    purchase = Purchase.find(params[:id])
    purchase.destroy!
    head :no_content
  end

  def add_payment
    purchase = Purchase.find(params[:id])
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

