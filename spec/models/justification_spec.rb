require "rails_helper"

RSpec.describe Justification, type: :model do
  def organization
    @organization ||= create_organization!(name: "ONG")
  end

  def account
    @account ||= Account.create!(email: "sub@example.com", google_uid: "uid-sub")
  end

  def insert_doc(payee:, amount:)
    SupportingDocument.insert(
      organization: organization,
      account: account,
      kind: "recibo",
      amount: amount,
      date: "2026-05-11",
      payee: payee,
      photo: photo_named("recibo-#{payee.parameterize}.jpg")
    )
  end

  it "declare two no-month documents persists amount_cents 20000" do
    doc_a = insert_doc(payee: "Padaria Central", amount: "155,00")
    doc_b = insert_doc(payee: "Mercado Silva", amount: "45,00")

    justification = described_class.declare(
      organization: organization,
      account: account,
      amount: "200,00",
      supporting_document_ids: [ doc_a.id, doc_b.id ]
    )

    expect(justification).to be_persisted
    expect(justification.amount_cents).to eq(20000)
    expect(justification.amount_cents).to be_a(Integer)
    expect(doc_a.reload.justification).to eq(justification)
    expect(doc_b.reload.justification).to eq(justification)
  end

  it "declare one document persists amount_cents 15500" do
    document = insert_doc(payee: "Padaria Central", amount: "155,00")

    justification = described_class.declare(
      organization: organization,
      account: account,
      amount: "155,00",
      supporting_document_ids: [ document.id ]
    )

    expect(justification.amount_cents).to eq(15500)
  end

  it "declare without documents is rejected" do
    justification = described_class.declare(
      organization: organization,
      account: account,
      amount: "200,00",
      supporting_document_ids: []
    )

    expect(justification).not_to be_persisted
    expect(Justification.count).to eq(0)
  end

  it "declare another Account document is rejected" do
    other = Account.create!(email: "other@example.com", google_uid: "uid-other")
    foreign = SupportingDocument.insert(
      organization: organization,
      account: other,
      kind: "recibo",
      amount: "155,00",
      date: "2026-05-11",
      payee: "Doc Alheio",
      photo: photo_named("alheio.jpg")
    )

    justification = described_class.declare(
      organization: organization,
      account: account,
      amount: "155,00",
      supporting_document_ids: [ foreign.id ]
    )

    expect(justification).not_to be_persisted
    expect(foreign.reload.justification_id).to be_nil
  end

  it "declare month document is rejected" do
    document = insert_doc(payee: "Padaria Central", amount: "155,00")
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 15500)
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])

    justification = described_class.declare(
      organization: organization,
      account: account,
      amount: "155,00",
      supporting_document_ids: [ document.id ]
    )

    expect(justification).not_to be_persisted
    expect(Justification.count).to eq(0)
  end

  it "declare already justified document is rejected" do
    document = insert_doc(payee: "Padaria Central", amount: "155,00")
    original = described_class.declare(
      organization: organization,
      account: account,
      amount: "155,00",
      supporting_document_ids: [ document.id ]
    )

    justification = described_class.declare(
      organization: organization,
      account: account,
      amount: "155,00",
      supporting_document_ids: [ document.id ]
    )

    expect(justification).not_to be_persisted
    expect(Justification.count).to eq(1)
    expect(document.reload.justification).to eq(original)
  end

  it "declare invalid spent amount is rejected" do
    document = insert_doc(payee: "Padaria Central", amount: "155,00")

    [ "0", "not-an-amount" ].each do |amount|
      justification = described_class.declare(
        organization: organization,
        account: account,
        amount: amount,
        supporting_document_ids: [ document.id ]
      )
      expect(justification).not_to be_persisted
    end

    expect(Justification.count).to eq(0)
    expect(document.reload.justification_id).to be_nil
  end

  it "replace_amount while members have no month persists 18000" do
    document = insert_doc(payee: "Padaria Central", amount: "155,00")
    justification = described_class.declare(
      organization: organization,
      account: account,
      amount: "200,00",
      supporting_document_ids: [ document.id ]
    )

    expect(justification.replace_amount("180,00")).to eq(true)
    expect(justification.reload.amount_cents).to eq(18000)
  end

  it "replace_amount with a month member is rejected" do
    document = insert_doc(payee: "Padaria Central", amount: "155,00")
    justification = described_class.declare(
      organization: organization,
      account: account,
      amount: "200,00",
      supporting_document_ids: [ document.id ]
    )
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 15500)
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document.reload ])

    expect(justification.replace_amount("180,00")).to eq(false)
    expect(justification.reload.amount_cents).to eq(20000)
  end

  describe "concurrent declare with the same document persists exactly one Justification" do
    self.use_transactional_tests = false

    it "concurrent declare with the same document persists exactly one Justification" do
      truncate_product_tables
      org = create_organization!(name: "ONG")
      acct = Account.create!(email: "sub@example.com", google_uid: "uid-sub")
      document = SupportingDocument.insert(
        organization: org,
        account: acct,
        kind: "recibo",
        amount: "155,00",
        date: "2026-05-11",
        payee: "Padaria Central",
        photo: photo_named("recibo-padaria.jpg")
      )

      run_in_parallel(2) do
        Justification.declare(
          organization: org,
          account: acct,
          amount: "155,00",
          supporting_document_ids: [ document.id ]
        )
      end

      expect(Justification.where(organization: org).count).to eq(1)
      expect(document.reload.justification).to be_present
    ensure
      truncate_product_tables
    end
  end
end
