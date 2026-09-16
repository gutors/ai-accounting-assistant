Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
    ENV.fetch("GOOGLE_CLIENT_ID", ""),
    ENV.fetch("GOOGLE_CLIENT_SECRET", ""),
    {
      scope: GoogleOauth.scope_string,
      access_type: "online",
      prompt: "select_account"
    }
end

OmniAuth.config.allowed_request_methods = %i[post]
OmniAuth.config.on_failure = proc do |_env|
  [ 302, { "Location" => "/login", "Content-Type" => "text/html" }, [] ]
end
