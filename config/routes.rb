Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get "dashboard", to: "dashboard#index"
      resources :products, only: %i[index show create update destroy]
      resources :vendors,  only: %i[index show create update destroy]
      resources :customers, only: %i[index show create update destroy]
      resources :invoices, only: %i[index show create update destroy]
      resources :purchases, only: %i[index show create update destroy] do
        member do
          post :add_payment
        end
      end
    end
  end
end
