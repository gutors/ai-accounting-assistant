Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "/login", to: "sessions#new", as: :login
  delete "/session", to: "sessions#destroy"
  get "/denied", to: "sessions#denied", as: :denied
  post "/dev/session", to: "development_sessions#create" unless Rails.env.production?

  get "/administration", to: "administration#show", as: :administration
  get "/administration/new", to: "administration#new", as: :new_administration
  get "/administration/:id/edit", to: "administration#edit", as: :edit_administration
  post "/administration", to: "administration#create"
  post "/administration/confirm", to: "administration#confirm"
  post "/administration/correct", to: "administration#correct"
  post "/administration/mail", to: "administration#mail"
  post "/administration/another", to: "administration#another"
  post "/administration/name", to: "administration#name_open"
  post "/administration/name/continue", to: "administration#name_continue"
  post "/administration/name/cancel", to: "administration#name_cancel"
  post "/administration/name/confirm", to: "administration#name_confirm"
  post "/administration/email/continue", to: "administration#email_continue"
  post "/administration/email/cancel", to: "administration#email_cancel"
  post "/administration/email/confirm", to: "administration#email_confirm"
  post "/administration/email", to: "administration#email_open"
  delete "/administration", to: "administration#destroy"

  get "/auth/google_oauth2/callback", to: "omniauth_callbacks#google_oauth2"
  get "/auth/failure", to: "omniauth_callbacks#failure"

  post "/coordinator_invites", to: "coordinator_invites#create"
  post "/coordinator_invites/:id/mail", to: "coordinator_invites#mail"
  delete "/coordinator_invites/:id", to: "coordinator_invites#destroy"
  post "/submitter_invites", to: "submitter_invites#create"
  post "/submitter_invites/:id/mail", to: "submitter_invites#mail"
  delete "/submitter_invites/:id", to: "submitter_invites#destroy"

  delete "/accesses/:id", to: "accesses#destroy"

  post "/focus", to: "focus#create"

  get "/setup", to: "setup#show"
  patch "/accountant", to: "accountants#update"
  patch "/package_archive", to: "package_archives#update"
  get "/sefaz_certificate", to: "sefaz_certificates#show"
  post "/sefaz_certificate", to: "sefaz_certificates#create"
  delete "/sefaz_certificate", to: "sefaz_certificates#destroy"
  post "/bank_accounts", to: "bank_accounts#create"
  patch "/bank_accounts/:id", to: "bank_accounts#update"
  post "/extra_exception_kinds", to: "extra_exception_kinds#create"
  patch "/extra_exception_kinds/:id", to: "extra_exception_kinds#update"
  delete "/extra_exception_kinds/:id", to: "extra_exception_kinds#destroy"
  patch "/base_document_exceptions/:kind", to: "base_document_exceptions#update"

  post "/months", to: "months#create"
  get "/months/:year_month", to: "months#show"
  get "/months/:year_month/matches", to: "matches#show"
  delete "/months/:year_month", to: "months#destroy"
  post "/months/:year_month/account_confirmation", to: "months#account_confirmation"
  post "/months/:year_month/close", to: "months#close"
  post "/months/:year_month/reopen", to: "months#reopen"
  post "/months/:year_month/restore", to: "months#restore"
  post "/months/:year_month/supporting_documents/:id/return", to: "month_returns#create"
  post "/months/:year_month/bank_statements", to: "bank_statements#create"
  post "/months/:year_month/matches", to: "matches#create"
  delete "/months/:year_month/matches/:id", to: "matches#destroy"
  post "/months/:year_month/document_exceptions", to: "document_exceptions#create"
  post "/months/:year_month/payments/:id/document_exception", to: "document_exceptions#create"
  delete "/months/:year_month/payments/:id/document_exception", to: "document_exceptions#destroy"

  get "/supporting_documents", to: "supporting_documents#index"
  get "/supporting_documents/:id/edit", to: "supporting_documents#edit"
  post "/supporting_documents/identify", to: "supporting_documents#identify"
  post "/supporting_documents", to: "supporting_documents#create"
  patch "/supporting_documents/:id", to: "supporting_documents#update"
  delete "/supporting_documents/:id", to: "supporting_documents#destroy"
  post "/supporting_documents/:id/sefaz_confirm", to: "supporting_documents#sefaz_confirm"
  post "/justifications", to: "justifications#create"
  patch "/justifications/:id", to: "justifications#update"

  root "organizations#show"
end
