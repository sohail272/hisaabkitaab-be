Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Authentication endpoints
      post "auth/onboard", to: "auth#onboard"
      get "auth/check_onboarding", to: "auth#check_onboarding"
      post "auth/login", to: "auth#login"
      get "auth/me", to: "auth#me"

      # Organization and Store management (org admin only)
      resources :stores, only: %i[index show create update] do
        collection do
          get :available
        end
      end

      # User management (org admin only)
      resources :users, only: %i[index show create update destroy]

      # Protected resources
      get "dashboard", to: "dashboard#index"
      resources :products, only: %i[index show create update destroy]
      resources :vendors,  only: %i[index show create update destroy]
      resources :customers, only: %i[index show create update destroy] do
        member do
          get :invoices
        end
      end
      resources :invoices, only: %i[index show create update destroy]
      resources :purchases, only: %i[index show create update destroy] do
        member do
          post :add_payment
        end
      end
    end
  end
end
