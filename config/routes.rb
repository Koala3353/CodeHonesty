Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root path
  root "static_pages#index"

  # Static pages
  get "about", to: "static_pages#about"
  get "privacy", to: "static_pages#privacy"
  get "terms", to: "static_pages#terms"

  # Authentication
  get "login", to: "sessions#new", as: :new_session
  delete "logout", to: "sessions#destroy", as: :destroy_session
  post "auth/magic_link", to: "sessions#send_magic_link", as: :send_magic_link
  get "auth/magic_link/:token", to: "sessions#create_from_email", as: :magic_link

  # OmniAuth callbacks
  get "auth/slack/callback", to: "sessions#create_from_slack"
  get "auth/github/callback", to: "sessions#create_from_github"
  get "auth/failure", to: "sessions#failure"

  # Users
  resources :users, only: [:show], param: :username do
    collection do
      get :settings
      patch :update
      post :create_api_key
      delete "api_keys/:id", to: "users#destroy_api_key", as: :destroy_api_key
    end
  end

  # Leaderboards
  resources :leaderboards, only: [:index, :show]

  # Slack integration
  post "slack/commands", to: "slack#commands"
  post "slack/events", to: "slack#events"

  # Doorkeeper OAuth routes
  use_doorkeeper

  # GoodJob admin UI (mounted at /good_job)
  authenticate :user, ->(user) { user.admin? } do
    mount GoodJob::Engine => "good_job"
  end

  # WakaTime-compatible API
  namespace :api do
    namespace :hackatime do
      namespace :v1 do
        # Heartbeats
        post "users/:id/heartbeats", to: "hackatime#create_heartbeat"
        post "users/:id/heartbeats.bulk", to: "hackatime#create_heartbeats_bulk"

        # Status bar (for editor plugins)
        get "users/:id/statusbar/today", to: "hackatime#statusbar_today"

        # Stats
        get "users/current/stats/last_7_days", to: "hackatime#stats_last_7_days"
      end
    end

    # Custom Hackatime API
    namespace :v1 do
      # Global stats (admin only)
      get "stats", to: "stats#index"

      # User public endpoints
      scope "users/:username" do
        get "stats", to: "users#stats"
        get "heartbeats/spans", to: "users#spans"
        get "projects", to: "users#projects"
        get "trust_factor", to: "users#trust_factor"
      end

      # OAuth-protected endpoints
      namespace :authenticated do
        get "me", to: "me#show"
        get "hours", to: "me#hours"
        get "streak", to: "me#streak"
        get "projects", to: "me#projects"
        get "heartbeats/latest", to: "me#heartbeats_latest"
        get "api_keys", to: "me#api_keys"
      end
    end

    # Admin API
    namespace :admin do
      namespace :v1 do
        get "check", to: "admin#check"
        get "user/info", to: "admin#user_info"
        get "user/stats", to: "admin#user_stats"
        post "user/convict", to: "admin#user_convict"
        post "execute", to: "admin#execute"
      end
    end
  end

  # Admin web interface
  namespace :admin do
    root to: "dashboard#index"
    resources :users, only: [:index, :show, :edit, :update, :destroy] do
      member do
        post :convict
      end
    end
  end
end
