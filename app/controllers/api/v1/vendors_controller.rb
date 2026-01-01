class Api::V1::VendorsController < ApplicationController
  def index
    render json: Vendor.order(updated_at: :desc).limit(200)
  end

  def show
    render json: Vendor.find(params[:id])
  end

  def create
    vendor = Vendor.create!(vendor_params)
    render json: vendor, status: :created
  end

  def update
    vendor = Vendor.find(params[:id])
    vendor.update!(vendor_params)
    render json: vendor
  end

  def destroy
    vendor = Vendor.find(params[:id])
    vendor.destroy!
    head :no_content
  end

  private

  def vendor_params
    params.require(:vendor).permit(
      :name,
      :phone,
      :email,
      :address,
      :active
    )
  end
end
