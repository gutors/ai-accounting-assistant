require "rails_helper"

RSpec.describe Suggestion, type: :model do
  def organization
    @organization ||= Organization.create!(name: "ONG")
  end

  def account
    @account ||= Account.create!(email: "coord@example.com", google_uid: "uid-coord")
  end

  def month_and_statement(year_month = "2026-05")
    @months ||= {}
    @months[year_month] ||= plant_month(organization, year_month: year_month)
  end

  def statement(year_month = "2026-05")
    month_and_statement(year_month)[1]
  end

  def proposals
    described_class.assign(organization)
  end

  def proposal_for(payment)
    proposals.find { |proposal| proposal.payments.map(&:id).include?(payment.id) }
  end

  it "equal 1:1 name hit assigns Padaria Central" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    proposal = proposal_for(payment)

    expect(proposal).to be_present
    expect(proposal.payments.map(&:id)).to eq([ payment.id ])
    expect(proposal.supporting_documents.map(&:id)).to eq([ document.id ])
  end

  it "assign does not persist a Match" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    described_class.assign(organization)

    expect(Match.count).to eq(0)
    expect(payment.reload.match_id).to be_nil
    expect(payment.document_exception_kind).to be_nil
    expect(payment.extra_exception_kind_id).to be_nil
    expect(document.reload.month_id).to be_nil
    expect(document.match_id).to be_nil
  end

  it "no unmatched document assigns nothing" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")

    expect(proposal_for(payment)).to be_nil
    expect(proposals).to be_empty
  end

  it "recibo equal 1:1 is assigned" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    expect(proposal_for(payment).supporting_documents).to eq([ document ])
    expect(document.kind).to eq("recibo")
  end

  it "nota_fiscal equal 1:1 is assigned" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    document = plant_nota(organization, account, payee: "Padaria Central", amount: "220,00")

    expect(proposal_for(payment).supporting_documents).to eq([ document ])
    expect(document.kind).to eq("nota_fiscal")
    expect(document.xml).to be_attached
  end
end
