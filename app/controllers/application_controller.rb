class ApplicationController < ActionController::API
  include Authenticatable

  protected

  # Helper method to get stores accessible by current user
  def accessible_stores
    if current_user.org_admin?
      current_user.organization.stores.where(active: true)
    elsif current_user.store_id
      Store.where(id: current_user.store_id, active: true)
    else
      Store.none
    end
  end

  # Helper method to scope queries by store
  def scope_by_store(relation)
    if current_user.org_admin?
      # Org admin can see all stores, but we can filter by store_id param if provided
      if params[:store_id].present?
        relation.where(store_id: params[:store_id])
      else
        relation.where(store_id: current_user.organization.store_ids)
      end
    elsif current_user.store_id
      relation.where(store_id: current_user.store_id)
    else
      relation.none
    end
  end
end
