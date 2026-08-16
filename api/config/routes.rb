Rails.application.routes.draw do
  resources :addresses do
    member do
      patch :restore
    end
  end
  resources :categories do
    member do
      patch :restore
    end
  end
  resources :connections
  resources :customers do
    member do
      patch :restore
    end
  end
  resources :quality_analyses

  resources :invoices, only: [ :index, :show ] do
    collection do
      get :eligible
      post :generate
      get :overdue
      get :cobranca_pdf
      get :print_filtered
    end

    member do
      get :pdf
      patch :pay
    end
  end

  resources :dashboard, only: [] do
    collection do
      get :summary
    end
  end

  # Test-only reset endpoint for the Maestro E2E suite — the block below is
  # never evaluated outside RAILS_ENV=test, so the route doesn't exist in
  # dev/production.
  if Rails.env.test?
    namespace :test do
      post "reset", to: "resets#create"
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
