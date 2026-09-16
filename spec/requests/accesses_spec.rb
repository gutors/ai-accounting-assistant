require "rails_helper"

RSpec.describe "Accesses", type: :request do
  it "DELETE /accesses/:id of a non-last coordinator redirects" do
    account, organization = plant_coordinator(email: "coord@example.com")
    other = Account.create!(email: "other@example.com", google_uid: "uid-other")
    other_access = Access.create!(account: other, organization: organization, kind: :coordinator)
    sign_in_as(account, organization: organization)

    delete "/accesses/#{other_access.id}"

    expect(Access.find_by(id: other_access.id)).to be_nil
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
  end

  it "DELETE last coordinator Access returns 422" do
    account, organization = plant_coordinator
    access = organization.accesses.coordinator.first
    sign_in_as(account, organization: organization)

    expect do
      delete "/accesses/#{access.id}"
    end.not_to change { organization.accesses.coordinator.count }

    expect(response).to have_http_status(:unprocessable_content)
  end

  describe "concurrent DELETE of last two returns 422 to the loser" do
    self.use_transactional_tests = false

    it "concurrent DELETE of last two returns 422 to the loser" do
      truncate_product_tables

      organization = Organization.create!(name: "ONG")
      account_a = Account.create!(email: "a@example.com", google_uid: "uid-a")
      account_b = Account.create!(email: "b@example.com", google_uid: "uid-b")
      access_a = Access.create!(account: account_a, organization: organization, kind: :coordinator)
      access_b = Access.create!(account: account_b, organization: organization, kind: :coordinator)

      session_a = signed_in_session(account_a)
      session_b = signed_in_session(account_b)
      headers = { "User-Agent" => ChromeUserAgent::CHROME }

      statuses = []
      mutex = Mutex.new
      threads = [
        Thread.new do
          session_a.delete("/accesses/#{access_a.id}", headers: headers)
          mutex.synchronize { statuses << session_a.response.status }
        end,
        Thread.new do
          session_b.delete("/accesses/#{access_b.id}", headers: headers)
          mutex.synchronize { statuses << session_b.response.status }
        end
      ]
      threads.each(&:join)

      expect(organization.accesses.coordinator.count).to eq(1)
      expect(statuses).to contain_exactly(302, 422)
    ensure
      truncate_product_tables
    end
  end

  it "DELETE /accesses/:id of another organization returns 404" do
    account, organization = plant_coordinator(email: "a@example.com", organization_name: "A")
    other_org = Organization.create!(name: "B")
    other_account = Account.create!(email: "b@example.com", google_uid: "uid-b")
    other_access = Access.create!(account: other_account, organization: other_org, kind: :coordinator)
    Access.create!(account: account, organization: other_org, kind: :coordinator)
    sign_in_as(account, organization: organization)

    delete "/accesses/#{other_access.id}"

    expect(response).to have_http_status(:not_found)
    expect(Access.find(other_access.id)).to eq(other_access)
  end

  def signed_in_session(account)
    host = ActionDispatch::Integration::Session.new(Rails.application)
    host.host = "www.example.com"
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: account.google_uid,
      info: { email: account.email, email_verified: true },
      extra: {
        raw_info: { "email" => account.email, "email_verified" => true },
        id_info: { "email_verified" => true }
      }
    )
    host.get "/auth/google_oauth2/callback", headers: { "User-Agent" => ChromeUserAgent::CHROME }
    host
  end
end
