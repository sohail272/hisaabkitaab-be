class Api::V1::ProductsController < ApplicationController
  def index
    q = params[:query].to_s.strip

    # Scope by store
    scope = scope_by_store(Product.includes(:vendor)).order(updated_at: :desc)

    if q.present?
      scope = scope.where(
        "name ILIKE :q OR sku ILIKE :q OR barcode ILIKE :q",
        q: "%#{q}%"
      )
    end

    render json: scope.limit(200).as_json(include: :vendor)
  end

  def show
    product = scope_by_store(Product).includes(:vendor).find(params[:id])
    render json: product.as_json(include: :vendor)
  end

  def create
    # Set store_id based on user's store or selected store (for org admin)
    store_id = params[:store_id] || current_user.store_id
    
    # For org admin, store_id must be provided or use default
    if current_user.org_admin? && !store_id
      render json: { error: 'store_id is required for organization admins' }, status: :bad_request
      return
    end

    product = scope_by_store(Product).build(product_params.merge(store_id: store_id))
    
    if product.save
      render json: product.reload.as_json(include: :vendor), status: :created
    else
      render json: { error: product.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def update
    product = scope_by_store(Product).find(params[:id])
    
    if product.update(product_params)
      render json: product.reload.as_json(include: :vendor)
    else
      render json: { error: product.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def destroy
    product = scope_by_store(Product).find(params[:id])
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
      :vendor_id,
      :store_id
    )
  end
end
