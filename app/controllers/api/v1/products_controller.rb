class Api::V1::ProductsController < ApplicationController
  def index
    q = params[:query].to_s.strip

    scope = Product.includes(:vendor).order(updated_at: :desc)

    if q.present?
      scope = scope.where(
        "name ILIKE :q OR sku ILIKE :q OR barcode ILIKE :q",
        q: "%#{q}%"
      )
    end

    render json: scope.limit(200).as_json(include: :vendor)
  end

  def show
    product = Product.includes(:vendor).find(params[:id])
    render json: product.as_json(include: :vendor)
  end

  def create
    product = Product.create!(product_params)
    render json: product.reload.as_json(include: :vendor), status: :created
  end

  def update
    product = Product.find(params[:id])
    product.update!(product_params)
    render json: product.reload.as_json(include: :vendor)
  end

  def destroy
    product = Product.find(params[:id])
    product.destroy!
    head :no_content
  end

  private

  def product_params
    params.require(:product).permit(
      :name,
      :description,
      :sku,
      :barcode,
      :purchase_price,
      :selling_price,
      :current_stock,
      :active,
      :vendor_id
    )
  end
end
