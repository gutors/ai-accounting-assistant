require "rails_helper"

RSpec.describe "DESIGN ledger row" do
  it "DESIGN ledger row Status and Documento not Acoes Resolver" do
    design = Rails.root.join("DESIGN.md").read
    ledger = design.split("### Ledger row", 2).last.split("### ", 2).first
    dos = design.split("### Do:", 2).last.split("### Don't:", 2).first

    expect(ledger).to include("Status")
    expect(ledger).to include("Documento")
    expect(ledger).to include("not a month-row action")
    expect(dos).to include("Status and Documento as separate columns on the month payment sheet")
    expect(dos).not_to include("Status and Ações as separate columns")
  end
end
