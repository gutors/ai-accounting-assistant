Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "/login", to: "sessions#new", as: :login
  delete "/session", to: "sessions#destroy"
  get "/denied", to: "sessions#denied", as: :denied

  get "/auth/google_oauth2/callback", to: "omniauth_callbacks#google_oauth2"
  get "/auth/failure", to: "omniauth_callbacks#failure"

  post "/coordinator_invites", to: "coordinator_invites#create"
  delete "/coordinator_invites/:id", to: "coordinator_invites#destroy"
  post "/submitter_invites", to: "submitter_invites#create"
  delete "/submitter_invites/:id", to: "submitter_invites#destroy"

  delete "/accesses/:id", to: "accesses#destroy"

  post "/focus", to: "focus#create"

  get "/setup", to: "setup#show"
  patch "/accountant", to: "accountants#update"
  patch "/package_archive", to: "package_archives#update"
  post "/bank_accounts", to: "bank_accounts#create"
  patch "/bank_accounts/:id", to: "bank_accounts#update"

  post "/months", to: "months#create"
  get "/months/:year_month", to: "months#show"
  post "/months/:year_month/close", to: "months#close"
  post "/months/:year_month/reopen", to: "months#reopen"
  post "/months/:year_month/bank_statements", to: "bank_statements#create"
  post "/months/:year_month/matches", to: "matches#create"
  delete "/months/:year_month/matches/:id", to: "matches#destroy"
  post "/months/:year_month/payments/:id/document_exception", to: "document_exceptions#create"
  delete "/months/:year_month/payments/:id/document_exception", to: "document_exceptions#destroy"

  get "/supporting_documents", to: "supporting_documents#index"
  post "/supporting_documents", to: "supporting_documents#create"
  patch "/supporting_documents/:id", to: "supporting_documents#update"
  delete "/supporting_documents/:id", to: "supporting_documents#destroy"

  root "organizations#show"
end
