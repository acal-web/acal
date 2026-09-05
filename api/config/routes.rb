Rails.application.routes.draw do
  root to: "version#show"

  resource :session, only: [ :create, :destroy ]
  get "me", to: "me#show"
  get "version", to: "version#show"
  resources :users do
    member do
      patch :restore, to: "users#restore"
    end
  end

  resources :addresses do
    member do
      patch :restore, to: "addresses#restore"
    end
  end
  resources :categories do
    member do
      patch :restore, to: "categories#restore"
    end
  end
  resources :connections
  resources :customers do
    member do
      patch :restore, to: "customers#restore"
    end
  end
  resources :quality_analyses

  resources :invoices, only: [ :index, :show ] do
    collection do
      get :eligible, to: "invoices#eligible"
      post :generate, to: "invoices#generate"
      get :overdue, to: "invoices#overdue"
      get :cobranca_pdf, to: "invoices#cobranca_pdf"
      get :print_filtered, to: "invoices#print_filtered"
      get :cashbox, to: "invoices#cashbox"
    end

    member do
      get :pdf, to: "invoices#pdf"
      patch :pay, to: "invoices#pay"
    end
  end

  resources :dashboard, only: [] do
    collection do
      get :summary, to: "dashboard#summary"
    end
  end

  resources :devices, only: [ :create ]

  resources :notifications, only: [ :index, :create ] do
    collection do
      get :recipients_count, to: "notifications#recipients_count"
    end
  end

  namespace :portal do
    resources :invoices, only: [ :index, :show ] do
      member do
        get :pdf, to: "invoices#pdf"
      end
    end
    resources :devices, only: [ :create ]
  end

  # Test-only reset endpoint for the Patrol/integration_test E2E suite — the
  # block below is never evaluated outside RAILS_ENV=test, so the route
  # doesn't exist in dev/production.
  if Rails.env.test?
    namespace :test do
      post "reset", to: "resets#create"
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
