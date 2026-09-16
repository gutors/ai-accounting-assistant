require "rails_helper"

RSpec.describe "OmniAuth" do
  it "google_oauth2 scopes are openid and email only" do
    expect(GoogleOauth.scopes).to contain_exactly("openid", "email")
    initializer = Rails.root.join("config/initializers/omniauth.rb").read
    expect(initializer).to include("scope: GoogleOauth.scope_string")
    expect(initializer).not_to match(/drive/i)
  end
end
