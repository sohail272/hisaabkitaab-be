class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:check_onboarding, :onboard, :login]

  # Check if onboarding is needed
  def check_onboarding
    if Organization.any?
      render json: { needs_onboarding: false }
    else
      render json: { needs_onboarding: true }
    end
  end

  # Login endpoint
  def login
    email = params[:email]
    password = params[:password]

    unless email && password
      render json: { error: 'Email and password are required' }, status: :bad_request
      return
    end

    user = User.find_by(email: email)

    unless user && user.authenticate(password)
      render json: { error: 'Invalid email or password' }, status: :unauthorized
      return
    end

    unless user.active?
      render json: { error: 'Account is inactive' }, status: :forbidden
      return
    end

    token = encode_token({
      user_id: user.id,
      organization_id: user.organization_id,
      store_id: user.store_id,
      role: user.role
    })

    render json: {
      token: token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        organization: {
          id: user.organization.id,
          name: user.organization.name,
          logo_url: user.organization.logo_url
        },
        store: user.store ? {
          id: user.store.id,
          name: user.store.name,
          code: user.store.code
        } : nil
      }
    }
  end

  # Onboarding endpoint (creates org, store, and first user)
  def onboard
    # Check if organization already exists
    if Organization.any?
      render json: { error: 'Organization already exists. Please login instead.' }, status: :bad_request
      return
    end

    organization_params = params.require(:organization).permit(:name, :phone, :email, :address)
    store_params = params.require(:store).permit(:name, :code, :address, :phone)
    user_params = params.require(:user).permit(:name, :email, :password, :phone)

    # Validate store code uniqueness
    if Store.exists?(code: store_params[:code])
      render json: { error: 'Store code already exists' }, status: :bad_request
      return
    end

    # Validate user email uniqueness
    if User.exists?(email: user_params[:email])
      render json: { error: 'Email already exists' }, status: :bad_request
      return
    end

    ActiveRecord::Base.transaction do
      # Create organization
      organization = Organization.create!(organization_params.merge(active: true))

      # Handle logo upload if present
      if params[:organization][:logo].present?
        logo_file = params[:organization][:logo]
        logo_url = save_logo(organization.id, logo_file)
        organization.update!(logo_url: logo_url)
      end

      # Create first store
      store = Store.create!(
        organization: organization,
        name: store_params[:name],
        code: store_params[:code],
        address: store_params[:address],
        phone: store_params[:phone],
        active: true
      )

      # Create first user (org admin)
      user = User.create!(
        organization: organization,
        store: nil, # Org admin has no store
        name: user_params[:name],
        email: user_params[:email],
        password: user_params[:password],
        phone: user_params[:phone],
        role: 'org_admin',
        active: true
      )

      # Generate token
      token = encode_token({
        user_id: user.id,
        organization_id: user.organization_id,
        store_id: nil,
        role: user.role
      })

      render json: {
        token: token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          organization: {
            id: organization.id,
            name: organization.name,
            logo_url: organization.logo_url
          },
          store: nil
        }
      }, status: :created
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  rescue => e
    render json: { error: e.message }, status: :internal_server_error
  end

  # Get current user info
  def me
    render json: {
      id: current_user.id,
      name: current_user.name,
      email: current_user.email,
      role: current_user.role,
      organization: {
        id: current_user.organization.id,
        name: current_user.organization.name,
        logo_url: current_user.organization.logo_url
      },
      store: current_user.store ? {
        id: current_user.store.id,
        name: current_user.store.name,
        code: current_user.store.code
      } : nil
    }
  end

  private

  def save_logo(organization_id, file)
    # Create storage directory if it doesn't exist
    storage_dir = Rails.root.join('storage', 'organizations', 'logos', organization_id.to_s)
    FileUtils.mkdir_p(storage_dir)

    # Get file extension
    ext = File.extname(file.original_filename)
    
    # Generate unique filename
    filename = "logo#{ext}"
    filepath = storage_dir.join(filename)

    # Save file
    File.open(filepath, 'wb') do |f|
      f.write(file.read)
    end

    # Return relative path for URL generation
    "/storage/organizations/logos/#{organization_id}/#{filename}"
  end

  def encode_token(payload)
    # Get secret key from Rails credentials or secrets
    secret_key = Rails.application.credentials.secret_key_base || Rails.application.secret_key_base || Rails.application.secrets.secret_key_base
    JWT.encode(payload, secret_key, 'HS256')
  end

  def secret_key
    @secret_key ||= Rails.application.credentials.secret_key_base || Rails.application.secret_key_base || Rails.application.secrets.secret_key_base
  end
end

