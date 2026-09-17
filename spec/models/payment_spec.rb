require "rails_helper"

RSpec.describe Payment, type: :model do
  def organization
    @organization ||= Organization.create!(name: "ONG")
  end

  def account
    @account ||= Account.create!(email: "coord@example.com", google_uid: "uid-coord")
  end

  def month_and_statement
    @month_and_statement ||= plant_month(organization)
  end

  def month
    month_and_statement[0]
  end

  def statement
    month_and_statement[1]
  end

  it "payment with no match and no exception is missing document" do
    payment = plant_payment(statement, 22000)

    expect(payment).to be_missing_document
    expect(Payment.for_month(month).missing_document).to include(payment)
  end

  it "mark bank_fee on missing-document payment" do
    payment = plant_payment(statement, 22000)

    payment.mark_document_exception("bank_fee")

    expect(payment.errors).to be_empty
    expect(payment.reload.document_exception_kind).to eq("bank_fee")
    expect(payment).not_to be_missing_document
  end

  it "mark accountant_fee on missing-document payment" do
    payment = plant_payment(statement, 22000)

    payment.mark_document_exception("accountant_fee")

    expect(payment.reload.document_exception_kind).to eq("accountant_fee")
    expect(payment).not_to be_missing_document
  end

  it "unmark bank_fee returns missing document" do
    payment = plant_payment(statement, 22000)
    payment.mark_document_exception("bank_fee")

    payment.unmark_document_exception

    expect(payment.reload.document_exception_kind).to be_nil
    expect(payment).to be_missing_document
  end

  it "rejects document_exception_kind that is not bank_fee or accountant_fee" do
    payment = plant_payment(statement, 22000)

    payment.mark_document_exception("doacao")

    expect(payment.errors[:base]).to include("Informe se é tarifa bancária ou honorário do contador")
    expect(payment.reload.document_exception_kind).to be_nil
  end

  it "rejects bank_fee on a matched payment" do
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])
    payment.reload

    payment.mark_document_exception("bank_fee")

    expect(payment.errors[:base]).to include("Desfaça o casamento antes de marcar a exceção")
    expect(payment.reload.document_exception_kind).to be_nil
    expect(payment.match_id).to be_present
  end

  it "document_exception_kind enum members are bank_fee and accountant_fee" do
    expect(Payment.document_exception_kinds.keys).to contain_exactly("bank_fee", "accountant_fee")
    expect(Payment.document_exception_kinds.values).to contain_exactly("bank_fee", "accountant_fee")
  end

  it "month has no missing document when every payment is matched or excepted" do
    matched = plant_payment(statement, 22000)
    excepted = plant_payment(statement, 10000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    Match.confirm(month: month, payments: [ matched ], supporting_documents: [ document ])
    excepted.mark_document_exception("bank_fee")

    expect(Payment.for_month(month).missing_document).to be_empty
  end

  it "mark exception while Month closed persists no mark" do
    payment = plant_payment(statement, 22000)
    month.update!(closed: true)

    payment.mark_document_exception("bank_fee")

    expect(payment.errors[:base]).to include("Mês fechado")
    expect(payment.reload.document_exception_kind).to be_nil
  end

  it "unmark exception while Month closed keeps the mark" do
    payment = plant_payment(statement, 22000)
    payment.mark_document_exception("bank_fee")
    month.update!(closed: true)

    payment.unmark_document_exception

    expect(payment.errors[:base]).to include("Mês fechado")
    expect(payment.reload.document_exception_kind).to eq("bank_fee")
  end
end
