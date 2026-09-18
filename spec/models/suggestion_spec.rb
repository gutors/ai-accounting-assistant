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

  it "document inserted after payment is assigned" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    expect(proposal_for(payment)).to be_nil

    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    expect(proposal_for(payment).supporting_documents).to eq([ document ])
  end

  it "equal rank name hit beats no name hit" do
    padaria = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    mercado = plant_payment(statement, 22000, history: "Pix enviado — Mercado Silva")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    expect(proposal_for(padaria).supporting_documents).to eq([ document ])
    expect(proposal_for(mercado)).to be_nil
  end

  it "equal name-hit tie breaks on lowest payment id" do
    first = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    second = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    expect(first.id).to be < second.id
    expect(proposal_for(first).supporting_documents).to eq([ document ])
    expect(proposal_for(second)).to be_nil
  end

  it "equal two docs name hit picks Padaria Central" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "220,00")

    proposal = proposal_for(payment)
    expect(proposal.supporting_documents).to eq([ padaria ])
    expect(proposal.supporting_documents).not_to include(mercado)
  end

  it "equal no-name-hit tie breaks on lowest document id" do
    payment = plant_payment(statement, 22000, history: "Pix")
    norte = plant_recibo(organization, account, payee: "Padaria Norte", amount: "220,00")
    sul = plant_recibo(organization, account, payee: "Padaria Sul", amount: "220,00")

    expect(norte.id).to be < sul.id
    expect(proposal_for(payment).supporting_documents).to eq([ norte ])
  end

  it "open-month name hit assigns May payment not June" do
    may = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    june = plant_payment(statement("2026-06"), 22000, history: "Pix enviado — Mercado Silva")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    expect(proposal_for(may).supporting_documents).to eq([ document ])
    expect(proposal_for(june)).to be_nil
  end

  it "cross-month equal tie breaks on lowest payment id" do
    may = plant_payment(statement, 22000, history: "Pix")
    june = plant_payment(statement("2026-06"), 22000, history: "Pix")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    lower = [ may, june ].min_by(&:id)
    other = [ may, june ].find { |payment| payment.id != lower.id }

    expect(proposal_for(lower).supporting_documents).to eq([ document ])
    expect(proposal_for(other)).to be_nil
  end

  it "document_on before occurred_on is still assigned" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central", occurred_on: Date.new(2026, 5, 20))
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00", date: "2026-04-30")

    expect(proposal_for(payment).supporting_documents).to eq([ document ])
    expect(document.document_on).to eq(Date.new(2026, 4, 30))
  end

  it "equal with no name hit still assigns" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Outro")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    expect(proposal_for(payment).supporting_documents).to eq([ document ])
  end

  it "name hit folds Jose to JOSE" do
    jose = plant_payment(statement, 22000, history: "Pix enviado — JOSE SILVA")
    mercado = plant_payment(statement, 22000, history: "Pix enviado — Mercado Silva")
    document = plant_recibo(organization, account, payee: "José Silva", amount: "220,00")

    expect(proposal_for(jose).supporting_documents).to eq([ document ])
    expect(proposal_for(mercado)).to be_nil
  end

  it "a Payment belongs to at most one suggestion" do
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    plant_recibo(organization, account, payee: "Mercado Silva", amount: "220,00")

    expect(proposals.count { |proposal| proposal.payments.map(&:id).include?(payment.id) }).to eq(1)
  end

  it "a SupportingDocument belongs to at most one suggestion" do
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    expect(proposals.count { |proposal| proposal.supporting_documents.map(&:id).include?(document.id) }).to eq(1)
  end
end
