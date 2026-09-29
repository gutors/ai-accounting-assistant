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

  it "DELETE last coordinator Access returns 404" do
    account, organization = plant_coordinator
    access = organization.accesses.coordinator.first
    sign_in_as(account, organization: organization)

    expect do
      delete "/accesses/#{access.id}"
    end.not_to change { organization.accesses.coordinator.count }

    expect(response).to have_http_status(:not_found)
    expect(response.body).to eq("")
  end

  describe "concurrent self-DELETE of two coordinators returns 404 and leaves both Accesses" do
    self.use_transactional_tests = false

    it "concurrent self-DELETE of two coordinators returns 404 and leaves both Accesses" do
      truncate_product_tables

      zoe, organization = plant_coordinator(email: "zoe@exemplo.org", organization_name: "ONG Norte", google_uid: "uid-zoe")
      ana = Account.create!(email: "ana@exemplo.org", google_uid: "uid-ana")
      access_zoe = organization.accesses.coordinator.find_by!(account: zoe)
      access_ana = Access.create!(account: ana, organization: organization, kind: :coordinator)

      session_a = signed_in_session(zoe)
      session_b = signed_in_session(ana)
      headers = { "User-Agent" => ChromeUserAgent::CHROME }
      destroy_calls = 0
      mutex = Mutex.new
      allow_any_instance_of(Access).to receive(:destroy).and_wrap_original do |method, *args, **kwargs|
        mutex.synchronize { destroy_calls += 1 }
        method.call(*args, **kwargs)
      end

      statuses = []
      threads = [
        Thread.new do
          session_a.delete("/accesses/#{access_zoe.id}", headers: headers)
          mutex.synchronize { statuses << session_a.response.status }
        end,
        Thread.new do
          session_b.delete("/accesses/#{access_ana.id}", headers: headers)
          mutex.synchronize { statuses << session_b.response.status }
        end
      ]
      threads.each(&:join)

      expect(statuses).to contain_exactly(404, 404)
      expect(Access.find(access_zoe.id)).to eq(access_zoe)
      expect(Access.find(access_ana.id)).to eq(access_ana)
      expect(destroy_calls).to eq(0)
    ensure
      truncate_product_tables
    end
  end

  it "DELETE /accesses/:id of another organization returns 404" do
    account, organization = plant_coordinator(email: "a@example.com", organization_name: "A")
    other_org = create_organization!(name: "B")
    other_account = Account.create!(email: "b@example.com", google_uid: "uid-b")
    other_access = Access.create!(account: other_account, organization: other_org, kind: :coordinator)
    Access.create!(account: account, organization: other_org, kind: :coordinator)
    sign_in_as(account, organization: organization)

    delete "/accesses/#{other_access.id}"

    expect(response).to have_http_status(:not_found)
    expect(Access.find(other_access.id)).to eq(other_access)
  end

  it "DELETE submitter Access redirects and keeps Account" do
    account, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    access = organization.accesses.submitter.find_by!(account: submitter)
    sign_in_as(account, organization: organization)

    delete "/accesses/#{access.id}"

    expect(Access.find_by(id: access.id)).to be_nil
    expect(Account.find(submitter.id)).to eq(submitter)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
  end

  it "DELETE last submitter Access leaves coordinator Accesses" do
    account, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    access = organization.accesses.submitter.find_by!(account: submitter)
    sign_in_as(account, organization: organization)

    delete "/accesses/#{access.id}"

    expect(organization.accesses.coordinator.pluck(:account_id)).to eq([ account.id ])
  end

  it "submitter DELETE /accesses/:id returns 404" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    access = organization.accesses.coordinator.first
    sign_in_as(submitter, organization: organization)

    delete "/accesses/#{access.id}"

    expect(response).to have_http_status(:not_found)
    expect(Access.find(access.id)).to eq(access)
  end

  it "principal DELETE of a peer coordinator Access redirects" do
    zoe, organization = plant_coordinator(email: "zoe@exemplo.org", organization_name: "ONG Norte", google_uid: "uid-zoe")
    ana = Account.create!(email: "ana@exemplo.org", google_uid: "uid-ana")
    ana_access = Access.create!(account: ana, organization: organization, kind: :coordinator)
    sign_in_as(zoe, organization: organization)

    delete "/accesses/#{ana_access.id}"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
    expect(Access.find_by(id: ana_access.id)).to be_nil
    expect(organization.accesses.coordinator.find_by(account: zoe)).to be_present
    expect(organization.reload.principal_coordinator_account).to eq(zoe)
  end

  it "principal DELETE of own coordinator Access returns 404" do
    zoe, organization = plant_coordinator(email: "zoe@exemplo.org", organization_name: "ONG Norte", google_uid: "uid-zoe")
    Access.create!(account: Account.create!(email: "ana@exemplo.org", google_uid: "uid-ana"), organization: organization, kind: :coordinator)
    access = organization.accesses.coordinator.find_by!(account: zoe)
    principal_id = organization.principal_coordinator_account_id
    sign_in_as(zoe, organization: organization)

    delete "/accesses/#{access.id}"

    expect(response).to have_http_status(:not_found)
    expect(response.body).to eq("")
    expect(Access.find(access.id)).to eq(access)
    expect(organization.reload.principal_coordinator_account_id).to eq(principal_id)
  end

  it "peer DELETE of the principal coordinator Access returns 404" do
    zoe, organization = plant_coordinator(email: "zoe@exemplo.org", organization_name: "ONG Norte", google_uid: "uid-zoe")
    ana = Account.create!(email: "ana@exemplo.org", google_uid: "uid-ana")
    Access.create!(account: ana, organization: organization, kind: :coordinator)
    zoe_access = organization.accesses.coordinator.find_by!(account: zoe)
    sign_in_as(ana, organization: organization)

    delete "/accesses/#{zoe_access.id}"

    expect(response).to have_http_status(:not_found)
    expect(response.body).to eq("")
    expect(Access.find(zoe_access.id)).to eq(zoe_access)
  end

  it "peer DELETE of another peer coordinator Access returns 404" do
    _zoe, organization = plant_coordinator(email: "zoe@exemplo.org", organization_name: "ONG Norte", google_uid: "uid-zoe")
    ana = Account.create!(email: "ana@exemplo.org", google_uid: "uid-ana")
    bia = Account.create!(email: "bia@exemplo.org", google_uid: "uid-bia")
    Access.create!(account: ana, organization: organization, kind: :coordinator)
    bia_access = Access.create!(account: bia, organization: organization, kind: :coordinator)
    sign_in_as(ana, organization: organization)

    delete "/accesses/#{bia_access.id}"

    expect(response).to have_http_status(:not_found)
    expect(Access.find(bia_access.id)).to eq(bia_access)
  end

  it "peer DELETE of own coordinator Access returns 404" do
    zoe, organization = plant_coordinator(email: "zoe@exemplo.org", organization_name: "ONG Norte", google_uid: "uid-zoe")
    ana = Account.create!(email: "ana@exemplo.org", google_uid: "uid-ana")
    ana_access = Access.create!(account: ana, organization: organization, kind: :coordinator)
    sign_in_as(ana, organization: organization)

    delete "/accesses/#{ana_access.id}"

    expect(response).to have_http_status(:not_found)
    expect(response.body).to eq("")
    expect(Access.find(ana_access.id)).to eq(ana_access)
    expect(organization.reload.principal_coordinator_account).to eq(zoe)
  end

  it "peer DELETE of a submitter Access redirects" do
    _zoe, organization = plant_coordinator(email: "zoe@exemplo.org", organization_name: "ONG Norte", google_uid: "uid-zoe")
    ana = Account.create!(email: "ana@exemplo.org", google_uid: "uid-ana")
    Access.create!(account: ana, organization: organization, kind: :coordinator)
    submitter, _ = plant_submitter(email: "submitter@exemplo.org", organization: organization)
    submitter_access = organization.accesses.submitter.find_by!(account: submitter)
    sign_in_as(ana, organization: organization)

    delete "/accesses/#{submitter_access.id}"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
    expect(Access.find_by(id: submitter_access.id)).to be_nil
  end

  it "unauthenticated DELETE /accesses/:id redirects to /login" do
    _zoe, organization = plant_coordinator(email: "zoe@exemplo.org", organization_name: "ONG Norte", google_uid: "uid-zoe")
    ana = Account.create!(email: "ana@exemplo.org", google_uid: "uid-ana")
    ana_access = Access.create!(account: ana, organization: organization, kind: :coordinator)

    expect {
      delete "/accesses/#{ana_access.id}"
    }.not_to change(Access, :count)

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
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
