module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def secret_key
    @secret_key ||= Rails.application.credentials.secret_key_base || Rails.application.secret_key_base || Rails.application.secrets.secret_key_base
  end

  def authenticate_user!
    token = extract_token_from_header
    
    unless token
      render json: { error: 'Authentication required' }, status: :unauthorized
      return
    end

    begin
      decoded = JWT.decode(token, secret_key, true, { algorithm: 'HS256' })
      user_id = decoded[0]['user_id']
      @current_user = User.find(user_id)
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound => e
      render json: { error: 'Invalid or expired token' }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end

  def extract_token_from_header
    auth_header = request.headers['Authorization']
    return nil unless auth_header

    # Support both "Bearer <token>" and just "<token>"
    auth_header.split(' ').last if auth_header
  end

  def encode_token(payload)
    JWT.encode(payload, secret_key, 'HS256')
  end
end

