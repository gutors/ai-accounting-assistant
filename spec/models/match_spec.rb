require "rails_helper"

RSpec.describe Match, type: :model do
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

  def confirm(payments:, documents:, observation: nil)
    Match.confirm(
      month: month,
      payments: payments,
      supporting_documents: documents,
      observation: observation
    )
  end

  it "confirm 1 payment 2 documents persists one Match" do
    payment = plant_payment(statement, 22000)
    doc_a = plant_recibo(organization, account, payee: "Padaria A", amount: "100,00")
    doc_b = plant_recibo(organization, account, payee: "Padaria B", amount: "120,00")

    match = confirm(payments: [ payment ], documents: [ doc_a, doc_b ])

    expect(match).to be_persisted
    expect(Match.where(month: month).count).to eq(1)
    expect(payment.reload.match_id).to eq(match.id)
    expect(doc_a.reload.match_id).to eq(match.id)
    expect(doc_b.reload.match_id).to eq(match.id)
  end

  it "confirm lesser with observation persists the Match" do
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "200,00")

    match = confirm(payments: [ payment ], documents: [ document ], observation: "desconto não documentado")

    expect(match).to be_persisted
    expect(match.observation).to eq("desconto não documentado")
  end

  it "rejects lesser without observation" do
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "200,00")

    match = confirm(payments: [ payment ], documents: [ document ])

    expect(match).not_to be_persisted
    expect(match.errors[:base]).to include("Informe a observação do casamento")
    expect(Match.count).to eq(0)
  end

  it "confirm greater without observation persists the Match" do
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "250,00")

    match = confirm(payments: [ payment ], documents: [ document ])

    expect(match).to be_persisted
  end

  it "confirm 1 payment 1 document persists one Match" do
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    match = confirm(payments: [ payment ], documents: [ document ])

    expect(match).to be_persisted
    expect(Match.count).to eq(1)
  end

  it "rejects 1 payment 0 documents" do
    payment = plant_payment(statement, 22000)

    match = confirm(payments: [ payment ], documents: [])

    expect(match).not_to be_persisted
    expect(match.errors[:base]).to include("Selecione ao menos um documento")
    expect(Match.count).to eq(0)
  end

  it "destroying a Match clears document Month and match_id" do
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    match = confirm(payments: [ payment ], documents: [ document ])

    match.dissolve

    expect(Match.count).to eq(0)
    expect(payment.reload.match_id).to be_nil
    expect(document.reload.match_id).to be_nil
    expect(document.month_id).to be_nil
    expect(payment).to be_missing_document
  end

  it "rejects a second Match on the same Payment" do
    payment = plant_payment(statement, 22000)
    first_doc = plant_recibo(organization, account, payee: "Padaria A", amount: "220,00")
    second_doc = plant_recibo(organization, account, payee: "Padaria B", amount: "220,00")
    confirm(payments: [ payment ], documents: [ first_doc ])

    match = confirm(payments: [ payment ], documents: [ second_doc ])

    expect(match).not_to be_persisted
    expect(match.errors[:base]).to include("Pagamento já está em um casamento")
    expect(Match.count).to eq(1)
  end

  it "rejects a second Match on the same SupportingDocument" do
    payment_a = plant_payment(statement, 22000)
    payment_b = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    confirm(payments: [ payment_a ], documents: [ document ])

    match = confirm(payments: [ payment_b ], documents: [ document ])

    expect(match).not_to be_persisted
    expect(match.errors[:base]).to include("Documento já está em um casamento")
    expect(Match.count).to eq(1)
  end

  it "Payment and SupportingDocument unique match_id" do
    payment = plant_payment(statement, 22000)
    doc_a = plant_recibo(organization, account, payee: "Padaria A", amount: "100,00")
    doc_b = plant_recibo(organization, account, payee: "Padaria B", amount: "120,00")
    extra = plant_recibo(organization, account, payee: "Extra", amount: "220,00")
    match = confirm(payments: [ payment ], documents: [ doc_a, doc_b ])

    expect(payment.reload.match_id).to eq(match.id)
    expect(doc_a.reload.match_id).to eq(match.id)
    expect(doc_b.reload.match_id).to eq(match.id)
    expect(Payment.where(id: payment.id).where.not(match_id: nil).count).to eq(1)
    expect(SupportingDocument.where(id: [ doc_a.id, doc_b.id ]).where.not(match_id: nil).count).to eq(2)

    second = confirm(payments: [ payment ], documents: [ extra ])
    expect(second).not_to be_persisted
    expect(Match.count).to eq(1)
  end

  it "confirm 2 payments 1 document persists one Match" do
    payment_a = plant_payment(statement, 10000)
    payment_b = plant_payment(statement, 12000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    match = confirm(payments: [ payment_a, payment_b ], documents: [ document ])

    expect(match).to be_persisted
    expect(Match.count).to eq(1)
    expect(payment_a.reload.match_id).to eq(match.id)
    expect(payment_b.reload.match_id).to eq(match.id)
  end

  it "confirm 3 payments 1 document persists one Match" do
    payments = [ 7000, 8000, 7000 ].map { |cents| plant_payment(statement, cents) }
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    match = confirm(payments: payments, documents: [ document ])

    expect(match).to be_persisted
    expect(Match.count).to eq(1)
  end

  it "rejects 2 payments 2 documents" do
    payment_a = plant_payment(statement, 10000)
    payment_b = plant_payment(statement, 12000)
    doc_a = plant_recibo(organization, account, payee: "Padaria A", amount: "100,00")
    doc_b = plant_recibo(organization, account, payee: "Padaria B", amount: "120,00")

    match = confirm(payments: [ payment_a, payment_b ], documents: [ doc_a, doc_b ])

    expect(match).not_to be_persisted
    expect(match.errors[:base]).to include("Casamento é um pagamento com um ou mais documentos, ou vários pagamentos com um documento")
    expect(Match.count).to eq(0)
  end

  it "rejects 0 payments 1 document" do
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    match = confirm(payments: [], documents: [ document ])

    expect(match).not_to be_persisted
    expect(match.errors[:base]).to include("Selecione ao menos um pagamento")
    expect(Match.count).to eq(0)
  end

  it "confirm on bank_fee payment clears the mark" do
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    payment.mark_document_exception("bank_fee")

    match = confirm(payments: [ payment ], documents: [ document ])

    expect(match).to be_persisted
    expect(payment.reload.document_exception_kind).to be_nil
    expect(payment.match_id).to eq(match.id)
  end

  describe "concurrent confirms sharing a document persist exactly one Match" do
    self.use_transactional_tests = false

    it "concurrent confirms sharing a document persist exactly one Match" do
      truncate_product_tables
      org = Organization.create!(name: "ONG")
      coord = Account.create!(email: "coord@example.com", google_uid: "uid-coord")
      opened, stmt = plant_month(org)
      payment_a = plant_payment(stmt, 22000)
      payment_b = plant_payment(stmt, 22000)
      document = plant_recibo(org, coord, payee: "Padaria Central", amount: "220,00")
      queue = Queue.new
      queue << payment_a.id
      queue << payment_b.id

      run_in_parallel(2) do
        Match.confirm(
          month: Month.find(opened.id),
          payments: [ Payment.find(queue.pop) ],
          supporting_documents: [ SupportingDocument.find(document.id) ]
        )
      end

      expect(Match.joins(:supporting_documents).where(supporting_documents: { id: document.id }).count).to eq(1)
      expect(SupportingDocument.find(document.id).match_id).to be_present
    ensure
      truncate_product_tables
    end
  end

  describe "concurrent confirms sharing a payment persist exactly one Match" do
    self.use_transactional_tests = false

    it "concurrent confirms sharing a payment persist exactly one Match" do
      truncate_product_tables
      org = Organization.create!(name: "ONG")
      coord = Account.create!(email: "coord@example.com", google_uid: "uid-coord")
      opened, stmt = plant_month(org)
      payment = plant_payment(stmt, 22000)
      doc_a = plant_recibo(org, coord, payee: "Padaria A", amount: "220,00")
      doc_b = plant_recibo(org, coord, payee: "Padaria B", amount: "220,00")
      queue = Queue.new
      queue << doc_a.id
      queue << doc_b.id

      run_in_parallel(2) do
        Match.confirm(
          month: Month.find(opened.id),
          payments: [ Payment.find(payment.id) ],
          supporting_documents: [ SupportingDocument.find(queue.pop) ]
        )
      end

      expect(Match.joins(:payments).where(payments: { id: payment.id }).count).to eq(1)
      expect(Payment.find(payment.id).match_id).to be_present
    ensure
      truncate_product_tables
    end
  end

  it "confirm while Month closed persists no Match" do
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    month.update!(closed: true)

    match = confirm(payments: [ payment ], documents: [ document ])

    expect(match.errors[:base]).to include("Mês fechado")
    expect(Match.count).to eq(0)
  end

  it "dissolve while Month closed keeps the Match" do
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    match = confirm(payments: [ payment ], documents: [ document ])
    month.update!(closed: true)

    match.dissolve

    expect(match.errors[:base]).to include("Mês fechado")
    expect(Match.exists?(match.id)).to eq(true)
  end
end
