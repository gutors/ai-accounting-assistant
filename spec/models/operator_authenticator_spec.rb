require "rails_helper"

RSpec.describe OperatorAuthenticator, type: :model do
  def auth_hash(email:, verified: true, uid: "uid-#{email}")
    OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: { email: email, email_verified: verified },
      extra: {
        raw_info: { "email" => email, "email_verified" => verified },
        id_info: { "email_verified" => verified, "email" => email }
      }
    )
  end

  it "pending submitter Invite with no Account signs in" do
    _coord, organization = plant_coordinator
    Invite.create!(organization: organization, email: "guest@example.com", kind: :submitter)

    result = described_class.call(auth_hash(email: "guest@example.com", uid: "uid-guest"))

    expect(result.status).to eq(:signed_in)
    account = Account.find_by!(email: "guest@example.com")
    expect(result.account).to eq(account)
    expect(result.organization).to eq(organization)
    expect(organization.accesses.find_by!(account: account).kind).to eq("submitter")
  end

  it "existing submitter Access with no pending Invite signs in" do
    account, organization = plant_submitter(email: "sub@example.com")

    result = described_class.call(auth_hash(email: "sub@example.com", uid: account.google_uid))

    expect(result.status).to eq(:signed_in)
    expect(result.account).to eq(account)
    expect(result.organization).to eq(organization)
    expect(Account.where(email: "sub@example.com").count).to eq(1)
    expect(organization.accesses.where(account: account).count).to eq(1)
  end

  it "coordinator of A accepts pending submitter Invite on B" do
    account, org_a = plant_coordinator(email: "mixed@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
    Invite.create!(organization: org_b, email: "mixed@example.com", kind: :submitter)

    result = described_class.call(auth_hash(email: "mixed@example.com", uid: account.google_uid))

    expect(result.status).to eq(:signed_in)
    expect(result.account).to eq(account)
    expect(Account.where(email: "mixed@example.com").count).to eq(1)
    expect(org_b.accesses.find_by!(account: account).kind).to eq("submitter")
    expect(Invite.find_by(email: "mixed@example.com")).to be_nil
    expect(result.organization).to eq(org_a)
  end

  it "Account with zero Access is denied" do
    account = Account.create!(email: "former@example.com", google_uid: "uid-former")

    result = described_class.call(auth_hash(email: "former@example.com", uid: "uid-former"))

    expect(result.status).to eq(:denied)
    expect(result.account).to eq(account)
    expect(result.organization).to be_nil
  end

  it "allowlisted email with no Account signs in with no organization" do
    result = with_env("ADMINISTRATOR_EMAIL" => "seller@example.com") do
      described_class.call(auth_hash(email: "seller@example.com", uid: "uid-seller"))
    end

    account = Account.find_by!(email: "seller@example.com")
    expect(result.status).to eq(:signed_in)
    expect(result.account).to eq(account)
    expect(result.organization).to be_nil
    expect(account.google_uid).to eq("uid-seller")
    expect(account.accesses).to be_empty
    expect(Organization.count).to eq(0)
  end

  it "allowlisted email with coordinator Access signs in to that organization" do
    account, organization = plant_coordinator(
      email: "seller@example.com",
      organization_name: "ONG Norte",
      google_uid: "uid-seller"
    )

    result = nil
    expect {
      result = with_env("ADMINISTRATOR_EMAIL" => "seller@example.com") do
        described_class.call(auth_hash(email: "seller@example.com", uid: "uid-seller"))
      end
    }.not_to change(Account, :count)

    expect(result.status).to eq(:signed_in)
    expect(result.account).to eq(account)
    expect(result.organization).to eq(organization)
  end

  it "allowlisted email with a pending Invite accepts the Invite" do
    organization = create_organization!(name: "ONG Norte")
    Invite.create!(organization: organization, email: "seller@example.com", kind: :coordinator)

    result = with_env("ADMINISTRATOR_EMAIL" => "seller@example.com") do
      described_class.call(auth_hash(email: "seller@example.com", uid: "uid-seller"))
    end

    account = Account.find_by!(email: "seller@example.com")
    expect(result.status).to eq(:signed_in)
    expect(result.account).to eq(account)
    expect(result.organization).to eq(organization)
    expect(Account.where(email: "seller@example.com").count).to eq(1)
    expect(organization.accesses.find_by!(account: account).kind).to eq("coordinator")
    expect(Invite.find_by(email: "seller@example.com")).to be_nil
  end

  it "verified email outside the allowlist is denied" do
    result = with_env("ADMINISTRATOR_EMAIL" => "seller@example.com") do
      described_class.call(auth_hash(email: "other@example.com", uid: "uid-other"))
    end

    expect(result.status).to eq(:denied)
    expect(Account.find_by(email: "other@example.com")).to be_nil
    expect(Organization.count).to eq(0)
  end

  it "unverified allowlisted email is unverified" do
    result = with_env("ADMINISTRATOR_EMAIL" => "seller@example.com") do
      described_class.call(auth_hash(email: "seller@example.com", verified: false, uid: "uid-seller"))
    end

    expect(result.status).to eq(:unverified)
    expect(Account.find_by(email: "seller@example.com")).to be_nil
  end

  it "blank administrator email denies a verified email with no Access" do
    [ nil, "" ].each do |value|
      result = with_env("ADMINISTRATOR_EMAIL" => value) do
        described_class.call(auth_hash(email: "stranger@example.com", uid: "uid-blank"))
      end

      expect(result.status).to eq(:denied)
      expect(Account.find_by(email: "stranger@example.com")).to be_nil
    end
  end

  it "mixed-case administrator email signs in with no organization" do
    result = with_env("ADMINISTRATOR_EMAIL" => "Seller@Example.com") do
      described_class.call(auth_hash(email: "seller@example.com", uid: "uid-seller"))
    end

    account = Account.find_by!(email: "seller@example.com")
    expect(result.status).to eq(:signed_in)
    expect(result.organization).to be_nil
    expect(account.google_uid).to eq("uid-seller")
    expect(Organization.count).to eq(0)
    expect(account.accesses).to be_empty
  end

  it "allowlisted Account with zero Access signs in with no organization" do
    account = Account.create!(email: "seller@example.com")

    result = nil
    expect {
      result = with_env("ADMINISTRATOR_EMAIL" => "seller@example.com") do
        described_class.call(auth_hash(email: "seller@example.com", uid: "uid-seller"))
      end
    }.not_to change(Account, :count)

    expect(result.status).to eq(:signed_in)
    expect(result.account).to eq(account)
    expect(result.organization).to be_nil
    expect(account.reload.google_uid).to eq("uid-seller")
    expect(Organization.count).to eq(0)
    expect(account.accesses).to be_empty
  end
end
