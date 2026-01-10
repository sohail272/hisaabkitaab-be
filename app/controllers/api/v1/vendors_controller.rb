class Api::V1::VendorsController < ApplicationController
  def index
    vendors = scope_by_store(Vendor).order(updated_at: :desc).limit(200)
    render json: vendors
  end

  def show
    vendor = scope_by_store(Vendor).find(params[:id])
    render json: vendor
  end

  def create
    # Set store_id based on user's store or selected store (for org admin)
    store_id = params[:store_id] || vendor_params[:store_id] || current_user.store_id
    
    # For org admin, store_id must be provided or use default
    if current_user.org_admin? && !store_id
      render json: { error: 'store_id is required for organization admins' }, status: :bad_request
      return
    end

    vendor = Vendor.new(vendor_params.merge(store_id: store_id))
    
    if vendor.save
      render json: vendor, status: :created
    else
      render json: { error: vendor.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def update
    vendor = scope_by_store(Vendor).find(params[:id])
    
    if vendor.update(vendor_params)
      render json: vendor
    else
      render json: { error: vendor.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def destroy
    vendor = scope_by_store(Vendor).find(params[:id])
    
    # Check if vendor has associated products or purchases
    if vendor.products.exists?
      render json: { error: "Cannot delete vendor. There are products associated with this vendor. Please remove or reassign the products first." }, status: :unprocessable_entity
      return
    end
    
    if vendor.purchases.exists?
      render json: { error: "Cannot delete vendor. There are purchases associated with this vendor." }, status: :unprocessable_entity
      return
    end
    
    vendor.destroy!
    head :no_content
  rescue ActiveRecord::RecordNotDestroyed => e
    render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  rescue ActiveRecord::InvalidForeignKey => e
    render json: { error: "Cannot delete vendor. It is still referenced by other records." }, status: :unprocessable_entity
  end

  private

  def vendor_params
    params.require(:vendor).permit(
      :name,
      :phone,
      :email,
      :address,
      :active,
      :store_id
    )
  end
end
