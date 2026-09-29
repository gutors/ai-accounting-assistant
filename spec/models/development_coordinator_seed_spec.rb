require "rails_helper"

RSpec.describe DevelopmentCoordinatorSeed, type: :model do
  it "plants ONG Exemplo and gutors@gmail.com with nil google_uid" do
    expect(Organization.count).to eq(0)
    expect(Account.count).to eq(0)
    expect(Access.count).to eq(0)

    described_class.plant!

    expect(Organization.count).to eq(1)
    organization = Organization.find_by!(name: "ONG Exemplo")
    expect(Account.count).to eq(1)
    account = Account.find_by!(email: "gutors@gmail.com")
    expect(account.google_uid).to be_nil
    expect(Access.count).to eq(1)
    access = Access.find_by!(account: account, organization: organization)
    expect(access.kind).to eq("coordinator")
    expect(organization.principal_coordinator_account).to eq(account)
    expect(Access.where(kind: "submitter").count).to eq(0)
    expect(Invite.count).to eq(0)
  end

  it "second plant leaves Organization Account and Access counts unchanged" do
    described_class.plant!

    expect { described_class.plant! }
      .not_to change { [ Organization.count, Account.count, Access.count ] }
  end

  it "existing gutors@gmail.com leaves counts and google_uid unchanged" do
    account = Account.create!(email: "gutors@gmail.com", google_uid: "uid-existing")

    expect { described_class.plant! }
      .not_to change { [ Organization.count, Access.count ] }

    expect(account.reload.google_uid).to eq("uid-existing")
  end

  it "raise from Account.create! before commit leaves counts unchanged" do
    allow(Account).to receive(:create!).and_wrap_original do |original, *args, **kwargs|
      original.call(*args, **kwargs)
      raise "before commit"
    end

    expect do
      expect { described_class.plant! }.to raise_error(RuntimeError, "before commit")
    end.not_to change { [ Organization.count, Account.count, Access.count ] }
  end
end
