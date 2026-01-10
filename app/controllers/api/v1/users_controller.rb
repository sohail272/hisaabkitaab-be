class Api::V1::UsersController < ApplicationController
  before_action :ensure_org_admin

  def index
    # Get all users in the organization
    users = current_user.organization.users.includes(:store).order(:name)
    render json: users.map { |user| user_json(user) }
  end

  def show
    user = current_user.organization.users.find(params[:id])
    render json: user_json(user)
  end

  def create
    user = current_user.organization.users.build(user_params)
    
    # Validate store assignment based on role
    if user.org_admin? && user.store_id.present?
      render json: { error: 'Organization admins cannot be assigned to a store' }, status: :unprocessable_entity
      return
    end

    if user.store_worker? || user.store_manager?
      unless user.store_id.present?
        render json: { error: 'Store workers and managers must be assigned to a store' }, status: :unprocessable_entity
        return
      end

      # Ensure store belongs to the organization
      unless current_user.organization.stores.exists?(id: user.store_id)
        render json: { error: 'Store does not belong to this organization' }, status: :unprocessable_entity
        return
      end
    end

    if user.save
      render json: user_json(user), status: :created
    else
      render json: { error: user.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def update
    user = current_user.organization.users.find(params[:id])
    
    # Prevent updating own role (security)
    if user.id == current_user.id && user_params[:role].present? && user_params[:role] != user.role
      render json: { error: 'You cannot change your own role' }, status: :forbidden
      return
    end

    # Validate store assignment based on role
    if user_params[:role] == 'org_admin' && user_params[:store_id].present?
      render json: { error: 'Organization admins cannot be assigned to a store' }, status: :unprocessable_entity
      return
    end

    if (user_params[:role] == 'store_worker' || user_params[:role] == 'store_manager')
      unless user_params[:store_id].present?
        render json: { error: 'Store workers and managers must be assigned to a store' }, status: :unprocessable_entity
        return
      end

      # Ensure store belongs to the organization
      unless current_user.organization.stores.exists?(id: user_params[:store_id])
        render json: { error: 'Store does not belong to this organization' }, status: :unprocessable_entity
        return
      end
    end

    # Handle password update separately (only if provided)
    update_params = user_params.except(:password)
    if user_params[:password].present?
      update_params[:password] = user_params[:password]
    end

    if user.update(update_params)
      render json: user_json(user)
    else
      render json: { error: user.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def destroy
    user = current_user.organization.users.find(params[:id])
    
    # Prevent deleting yourself
    if user.id == current_user.id
      render json: { error: 'You cannot delete your own account' }, status: :forbidden
      return
    end

    if user.destroy
      head :no_content
    else
      render json: { error: user.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :phone, :role, :store_id, :active)
  end

  def user_json(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
      active: user.active,
      organization_id: user.organization_id,
      store: user.store ? {
        id: user.store.id,
        name: user.store.name,
        code: user.store.code
      } : nil,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end

  def ensure_org_admin
    unless current_user.org_admin?
      render json: { error: 'Only organization admins can manage users' }, status: :forbidden
    end
  end
end

