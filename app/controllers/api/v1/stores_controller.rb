class Api::V1::StoresController < ApplicationController
  before_action :ensure_org_admin, only: [:create, :update]

  def index
    stores = accessible_stores.order(:name)
    render json: stores.map { |store| store_json(store) }
  end

  def show
    store = accessible_stores.find(params[:id])
    render json: store_json(store)
  end

  def create
    store = current_user.organization.stores.build(store_params)
    
    if store.save
      render json: store_json(store), status: :created
    else
      render json: { error: store.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def update
    store = current_user.organization.stores.find(params[:id])
    
    if store.update(store_params)
      render json: store_json(store)
    else
      render json: { error: store.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def available
    # Returns all stores for org admin, or current user's store
    stores = if current_user.org_admin?
      current_user.organization.stores.where(active: true).order(:name)
    elsif current_user.store_id
      [current_user.store].compact
    else
      []
    end
    
    render json: stores.map { |store| store_json(store) }
  end

  private

  def store_params
    params.require(:store).permit(:name, :code, :address, :phone, :email, :active)
  end

  def store_json(store)
    {
      id: store.id,
      name: store.name,
      code: store.code,
      address: store.address,
      phone: store.phone,
      email: store.email,
      active: store.active,
      organization_id: store.organization_id
    }
  end

  def ensure_org_admin
    unless current_user.org_admin?
      render json: { error: 'Only organization admins can manage stores' }, status: :forbidden
    end
  end
end

