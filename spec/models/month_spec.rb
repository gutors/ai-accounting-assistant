require "rails_helper"

RSpec.describe Month, type: :model do
  def organization
    @organization ||= Organization.create!(name: "ONG")
  end

  it "opens 2026-05 for the organization" do
    month = Month.open(organization: organization, year_month: "2026-05")

    expect(month).to be_persisted
    expect(month.year_month).to eq("2026-05")
    expect(month.organization).to eq(organization)
    expect(organization.months.where(year_month: "2026-05").count).to eq(1)
  end

  it "finds existing 2026-05 rather than creating a second" do
    first = Month.open(organization: organization, year_month: "2026-05")
    second = Month.open(organization: organization, year_month: "2026-05")

    expect(second).to eq(first)
    expect(organization.months.where(year_month: "2026-05").count).to eq(1)
  end

  it "rejects year_month 2026-13" do
    month = Month.open(organization: organization, year_month: "2026-13")

    expect(month).not_to be_persisted
    expect(organization.months.count).to eq(0)
  end

  describe "concurrent opens persist exactly one Month" do
    self.use_transactional_tests = false

    it "concurrent opens persist exactly one Month" do
      truncate_product_tables
      org = Organization.create!(name: "ONG")

      run_in_parallel(2) do
        Month.open(organization: org, year_month: "2026-05")
      rescue ActiveRecord::RecordNotUnique
        nil
      end

      expect(Month.where(organization: org, year_month: "2026-05").count).to eq(1)
    ensure
      truncate_product_tables
    end
  end
end
