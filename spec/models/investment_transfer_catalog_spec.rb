require "rails_helper"

RSpec.describe InvestmentTransferCatalog, type: :model do
  it "COMPE 001 debit Transferencia BB Rende Facil is a catalog match" do
    expect(
      described_class.debit?(compe: "001", history: "Transferência — BB Rende Fácil")
    ).to eq(true)
  end

  it "COMPE 001 debit RENDE FACIL and rende facil match like Rende Facil" do
    expect(described_class.debit?(compe: "001", history: "RENDE FACIL")).to eq(true)
    expect(described_class.debit?(compe: "001", history: "rende facil")).to eq(true)
    expect(described_class.debit?(compe: "001", history: "Rende Fácil")).to eq(true)
  end

  it "COMPE 033 debit Transferencia BB Rende Facil is not a catalog match" do
    expect(
      described_class.debit?(compe: "033", history: "Transferência — BB Rende Fácil")
    ).to eq(false)
  end

  it "COMPE 001 credit containing Rende Facil is not a catalog match" do
    movement = StatementSpreadsheet::Movement.new(
      occurred_on: Date.new(2026, 5, 4),
      amount_cents: 1000,
      history: "Transferência — BB Rende Fácil",
      credit: true
    )

    expect(described_class.movement?(compe: "001", movement: movement)).to eq(false)
  end
end
