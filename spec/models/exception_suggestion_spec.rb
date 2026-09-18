require "rails_helper"

RSpec.describe ExceptionSuggestion, type: :model do
  def organization
    @organization ||= Organization.create!(name: "ONG")
  end

  def account
    @account ||= Account.create!(email: "coord@example.com", google_uid: "uid-coord")
  end

  def statement(year_month = "2026-05")
    @statements ||= {}
    @statements[year_month] ||= plant_month(organization, year_month: year_month)[1]
  end

  def proposals
    described_class.assign(organization)
  end

  def proposal_for(payment)
    proposals.find { |proposal| proposal.payment.id == payment.id }
  end

  def set_pix(key)
    organization.update!(accountant_presentation_name: "Ana Contadora", accountant_pix_key: key)
  end

  it "PIX substring hit proposes accountant_fee" do
    set_pix("chave-pix")
    payment = plant_payment(statement, 22000, history: "Pix enviado chave-pix")

    proposal = proposal_for(payment)

    expect(proposal).to be_present
    expect(proposal.kind).to eq("accountant_fee")
    expect(proposal.payment.id).to eq(payment.id)
  end

  it "assign does not persist accountant_fee" do
    set_pix("chave-pix")
    payment = plant_payment(statement, 22000, history: "Pix enviado chave-pix")

    described_class.assign(organization)

    expect(payment.reload.document_exception_kind).to be_nil
  end

  it "tax id digit form hits history digits" do
    organization.update!(accountant_presentation_name: "Ana Contadora", accountant_tax_id: "39053344705")
    payment = plant_payment(statement, 22000, history: "Pix 390.533.447-05")

    expect(proposal_for(payment).kind).to eq("accountant_fee")
  end

  it "PIX email downcased is a substring of history" do
    set_pix("ana@example.com")
    payment = plant_payment(statement, 22000, history: "Pix Ana@Example.com")

    expect(proposal_for(payment).kind).to eq("accountant_fee")
  end

  it "PIX with digits hits digit-only history" do
    set_pix("51999999999")
    payment = plant_payment(statement, 22000, history: "Pix +55 51 99999-9999")

    expect(proposal_for(payment).kind).to eq("accountant_fee")
  end

  it "PIX uuid with digits hits digit-only history" do
    set_pix("f9c8d7e6-1234-4abc-9def-0123456789ab")
    payment = plant_payment(statement, 22000, history: "Pix F9C8D7E6-1234-4ABC-9DEF-0123456789AB")

    expect(proposal_for(payment).kind).to eq("accountant_fee")
  end

  it "two PIX hits are two proposals" do
    set_pix("chave-pix")
    first = plant_payment(statement, 22000, history: "Pix enviado chave-pix A")
    second = plant_payment(statement, 15000, history: "Pix enviado chave-pix B")

    expect(proposal_for(first).kind).to eq("accountant_fee")
    expect(proposal_for(second).kind).to eq("accountant_fee")
    expect(proposals.size).to eq(2)
  end

  it "presentation name never hits" do
    organization.update!(accountant_presentation_name: "Ana Contadora")
    payment = plant_payment(statement, 22000, history: "Pix Ana Contadora")

    expect(proposal_for(payment)).to be_nil
  end

  it "legal name never hits" do
    organization.update!(accountant_presentation_name: "Ana", accountant_legal_name: "Ana Contabilidade LTDA")
    payment = plant_payment(statement, 22000, history: "Pix Ana Contabilidade LTDA")

    expect(proposal_for(payment)).to be_nil
  end

  it "blank PIX and tax id never proposes" do
    payment = plant_payment(statement, 22000, history: "Pix 390.533.447-05")

    expect(proposal_for(payment)).to be_nil
  end

  it "match suggestion suppresses exception suggestion" do
    set_pix("chave-pix")
    payment = plant_payment(statement, 22000, history: "Pix enviado chave-pix — Padaria Central")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    expect(proposal_for(payment)).to be_nil
  end

  it "lesser match suggestion suppresses exception suggestion" do
    set_pix("chave-pix")
    payment = plant_payment(statement, 50000, history: "Pix enviado chave-pix")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "200,00")

    expect(proposal_for(payment)).to be_nil
  end

  it "tarifa history without PIX does not propose" do
    payment = plant_payment(statement, 22000, history: "Tarifa Pacote de Serviços")

    expect(proposal_for(payment)).to be_nil
  end

  it "never proposes an extra exception kind" do
    ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    set_pix("chave-pix")
    payment = plant_payment(statement, 22000, history: "Pix enviado chave-pix")

    expect(proposal_for(payment).kind).to eq("accountant_fee")
    expect(proposals.map(&:kind).uniq).to eq([ "accountant_fee" ])
  end
end
