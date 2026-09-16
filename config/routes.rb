Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "/login", to: "sessions#new", as: :login
  delete "/session", to: "sessions#destroy"
  get "/denied", to: "sessions#denied", as: :denied

  get "/auth/google_oauth2/callback", to: "omniauth_callbacks#google_oauth2"
  get "/auth/failure", to: "omniauth_callbacks#failure"

  post "/coordinator_invites", to: "coordinator_invites#create"
  delete "/coordinator_invites/:id", to: "coordinator_invites#destroy"

  delete "/accesses/:id", to: "accesses#destroy"

  post "/focus", to: "focus#create"

  root "organizations#show"
end
