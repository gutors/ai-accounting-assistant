module AuthHelpers
  def stub_google_oauth(email:, verified: true, uid: "google-#{email}")
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: { email: email, email_verified: verified },
      extra: {
        raw_info: { "email" => email, "email_verified" => verified },
        id_info: { "email_verified" => verified, "email" => email }
      }
    )
  end

  def google_callback(email:, verified: true, uid: "google-#{email}")
    stub_google_oauth(email: email, verified: verified, uid: uid)
    get "/auth/google_oauth2/callback"
  end

  def sign_in_as(account, organization:, uid: account.google_uid.presence || "google-#{account.email}")
    google_callback(email: account.email, uid: uid)
    expect(session[:account_id]).to eq(account.id)
    post "/focus", params: { organization_id: organization.id } if session[:organization_id] != organization.id
  end
end
