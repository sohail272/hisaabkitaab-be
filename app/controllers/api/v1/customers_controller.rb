class Api::V1::CustomersController < ApplicationController
  def index
    q = params[:query].to_s.strip
    phone = params[:phone].to_s.strip
    
    # If phone is provided, return customer by phone
    if phone.present?
      customer = Customer.where(phone: phone).first
      return render json: customer if customer
      return render json: nil
    end
    
    scope = Customer.order(updated_at: :desc)
    
    if q.present?
      scope = scope.where(
        "name ILIKE :q OR phone ILIKE :q OR email ILIKE :q",
        q: "%#{q}%"
      )
    end
    
    render json: scope.limit(200)
  end

  def show
    render json: Customer.find(params[:id])
  end

  def create
    customer = Customer.create!(customer_params)
    render json: customer, status: :created
  end

  def update
    customer = Customer.find(params[:id])
    customer.update!(customer_params)
    render json: customer
  end

  def destroy
    customer = Customer.find(params[:id])
    customer.destroy!
    head :no_content
  end

  private

  def customer_params
    params.require(:customer).permit(
      :name,
      :phone,
      :email,
      :address,
      :active
    )
  end
end

