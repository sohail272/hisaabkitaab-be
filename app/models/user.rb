class User < ApplicationRecord
  belongs_to :organization
  belongs_to :store, optional: true

  has_secure_password

  enum role: {
    store_worker: 'store_worker',
    store_manager: 'store_manager',
    org_admin: 'org_admin'
  }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }
  validates :role, presence: true

  # Org admin must not have a store
  validate :org_admin_has_no_store

  def org_admin?
    role == 'org_admin'
  end

  def store_manager?
    role == 'store_manager'
  end

  def store_worker?
    role == 'store_worker'
  end

  private

  def org_admin_has_no_store
    if org_admin? && store_id.present?
      errors.add(:store_id, "Organization admin cannot be assigned to a store")
    end
  end
end

