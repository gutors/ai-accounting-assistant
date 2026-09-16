require "rails_helper"

RSpec.describe Account, type: :model do
  it "rejects a second Account for the same normalized email" do
    Account.create!(email: "  Coord@Example.com ", google_uid: "uid-1")

    duplicate = Account.new(email: "coord@example.com", google_uid: "uid-2")

    expect(duplicate).not_to be_valid
    expect(Account.where(email: "coord@example.com").count).to eq(1)
  end

  it "rejects a second Account for the same Google uid" do
    Account.create!(email: "one@example.com", google_uid: "same-uid")

    duplicate = Account.new(email: "two@example.com", google_uid: "same-uid")

    expect(duplicate).not_to be_valid
  end
end
