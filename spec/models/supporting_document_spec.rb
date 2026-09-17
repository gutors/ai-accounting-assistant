require "rails_helper"

RSpec.describe SupportingDocument, type: :model do
  def organization
    @organization ||= Organization.create!(name: "ONG")
  end

  def account
    @account ||= Account.create!(email: "coord@example.com", google_uid: "uid-coord")
  end

  def insert_doc(**overrides)
    SupportingDocument.insert(
      **{
        organization: organization,
        account: account,
        kind: "recibo",
        amount: "155,00",
        date: "2026-05-11",
        payee: "Padaria Central",
        photo: photo_jpg,
        xml: nil
      }.merge(overrides)
    )
  end

  it "insert recibo jpg persists one SupportingDocument for the organization" do
    doc = insert_doc

    expect(doc).to be_persisted
    expect(doc.organization).to eq(organization)
    expect(SupportingDocument.where(organization: organization).count).to eq(1)
  end

  it "insert recibo amount_cents is Integer 15500" do
    doc = insert_doc

    expect(doc.amount_cents).to be_a(Integer)
    expect(doc.amount_cents).to eq(15500)
  end

  it "insert recibo attaches photo via Active Storage and no xml" do
    doc = insert_doc

    expect(doc.photo).to be_attached
    expect(doc.photo.blob.service_name).to eq("test")
    expect(doc.xml).not_to be_attached
    expect(Rails.root.join("config/storage.yml").read).not_to match(/Drive/)
  end

  it "insert recibo belongs to inserting Account and no Month" do
    doc = insert_doc

    expect(doc.account).to eq(account)
    expect(doc.month).to be_nil
  end

  it "rejects recibo without photo" do
    doc = insert_doc(photo: nil)

    expect(doc).not_to be_persisted
    expect(SupportingDocument.count).to eq(0)
  end

  it "rejects recibo with xml" do
    doc = insert_doc(xml: xml_file)

    expect(doc).not_to be_persisted
    expect(SupportingDocument.count).to eq(0)
  end

  it "insert nota_fiscal photo has photo and no xml" do
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg, xml: nil)

    expect(doc).to be_persisted
    expect(doc.photo).to be_attached
    expect(doc.xml).not_to be_attached
  end

  it "insert nota_fiscal xml has xml and no photo" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: xml_file)

    expect(doc).to be_persisted
    expect(doc.xml).to be_attached
    expect(doc.photo).not_to be_attached
  end

  it "insert nota_fiscal with photo and xml attaches both" do
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg, xml: xml_file)

    expect(doc).to be_persisted
    expect(doc.photo).to be_attached
    expect(doc.xml).to be_attached
  end

  it "rejects nota_fiscal without photo and xml" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: nil)

    expect(doc).not_to be_persisted
    expect(SupportingDocument.count).to eq(0)
  end

  it "insert ignores xml vNF and keeps typed 15500" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: xml_with_vnf, amount: "155,00")

    expect(doc.amount_cents).to eq(15500)
  end

  it "lists by document date descending then id descending" do
    older = insert_doc(date: "2026-05-11", payee: "Older")
    newer = insert_doc(date: "2026-05-12", payee: "Newer")
    expect(SupportingDocument.listed).to eq([ newer, older ])

    first = insert_doc(date: "2026-05-10", payee: "Tie A")
    second = insert_doc(date: "2026-05-10", payee: "Tie B")
    tied = SupportingDocument.listed.select { |row| row.document_on == Date.new(2026, 5, 10) }
    expect(tied).to eq([ second, first ])
  end

  it "insert duplicate amount date payee persists both" do
    insert_doc
    insert_doc

    expect(SupportingDocument.where(organization: organization, payee: "Padaria Central").count).to eq(2)
  end

  it "update payee to Mercado Silva" do
    doc = insert_doc
    doc.apply(payee: "Mercado Silva")

    expect(doc.reload.payee).to eq("Mercado Silva")
  end

  it "update payee keeps photo and xml blobs" do
    doc = insert_doc(kind: "nota_fiscal", photo: photo_named("danfe.jpg"), xml: xml_file("autorizada.xml"))
    doc.apply(payee: "Mercado Silva")

    doc.reload
    expect(doc.photo.filename.to_s).to eq("danfe.jpg")
    expect(doc.xml.filename.to_s).to eq("autorizada.xml")
  end

  it "update photo replaces the photo blob" do
    doc = insert_doc(photo: photo_named("foto-antiga.jpg"))
    doc.apply(photo: photo_named("foto-nova.jpg"))

    expect(doc.reload.photo.filename.to_s).to eq("foto-nova.jpg")
  end

  it "insert with observation pago em dinheiro" do
    doc = insert_doc(observation: "pago em dinheiro")

    expect(doc.observation).to eq("pago em dinheiro")
  end

  it "insert blank observation stores none" do
    doc = insert_doc(observation: "")

    expect(doc).to be_persisted
    expect(doc.observation).to be_nil
  end

  it "rejects amount 0 and blank amount" do
    [ "0", "" ].each do |amount|
      doc = insert_doc(amount: amount)
      expect(doc).not_to be_persisted
    end
    expect(SupportingDocument.count).to eq(0)
  end

  it "rejects blank payee" do
    doc = insert_doc(payee: "  ")

    expect(doc).not_to be_persisted
    expect(SupportingDocument.count).to eq(0)
  end

  it "rejects invalid date" do
    doc = insert_doc(date: "not-a-date")

    expect(doc).not_to be_persisted
    expect(SupportingDocument.count).to eq(0)
  end

  it "rejects kind that is not nota_fiscal or recibo" do
    doc = insert_doc(kind: "invoice")

    expect(doc).not_to be_persisted
    expect(SupportingDocument.count).to eq(0)
  end

  it "rejects photo or xml larger than 10485760 bytes" do
    photo_doc = insert_doc(photo: oversized_photo)
    xml_doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: oversized_xml)

    expect(photo_doc).not_to be_persisted
    expect(xml_doc).not_to be_persisted
    expect(SupportingDocument.count).to eq(0)
  end

  it "rejects photo extension heic" do
    doc = insert_doc(photo: photo_heic)

    expect(doc).not_to be_persisted
    expect(SupportingDocument.count).to eq(0)
  end

  it "rejects xml extension txt" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: xml_txt)

    expect(doc).not_to be_persisted
    expect(SupportingDocument.count).to eq(0)
  end

  it "rejects payee longer than 200 characters" do
    doc = insert_doc(payee: "a" * 201)

    expect(doc).not_to be_persisted
    expect(SupportingDocument.count).to eq(0)
  end

  it "rejects kind recibo on xml-only without photo" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: xml_file)
    doc.apply(kind: "recibo")

    expect(doc.errors[:base]).to include("Envie a foto do recibo")
    expect(doc.reload.kind).to eq("nota_fiscal")
    expect(doc.xml).to be_attached
  end

  it "update kind recibo with photo purges xml" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: xml_file)
    doc.apply(kind: "recibo", photo: photo_named("recibo-novo.jpg"))

    doc.reload
    expect(doc.kind).to eq("recibo")
    expect(doc.photo.filename.to_s).to eq("recibo-novo.jpg")
    expect(doc.xml).not_to be_attached
  end

  it "kind enum members are nota_fiscal and recibo" do
    expect(SupportingDocument.kinds.keys).to contain_exactly("nota_fiscal", "recibo")
  end

  it "has_one_attached photo and xml" do
    expect(SupportingDocument.reflect_on_attachment(:photo)).to be_present
    expect(SupportingDocument.reflect_on_attachment(:xml)).to be_present
  end

  it "insert accepts photo extensions jpg jpeg png webp pdf" do
    %w[jpg jpeg png webp pdf].each do |ext|
      doc = insert_doc(photo: photo_with_ext(ext), payee: "Payee #{ext}")
      expect(doc).to be_persisted
      expect(doc.photo.filename.to_s).to eq("foto.#{ext}")
    end
    expect(SupportingDocument.count).to eq(5)
  end

  describe "concurrent recibo inserts persist two SupportingDocuments" do
    self.use_transactional_tests = false

    it "concurrent recibo inserts persist two SupportingDocuments" do
      truncate_product_tables
      org = Organization.create!(name: "ONG")
      inserter = Account.create!(email: "coord@example.com")

      run_in_parallel(2) do
        SupportingDocument.insert(
          organization: org,
          account: inserter,
          kind: "recibo",
          amount: "155,00",
          date: "2026-05-11",
          payee: "Padaria Central",
          photo: photo_jpg("recibo-#{Thread.current.object_id}.jpg")
        )
      end

      expect(SupportingDocument.where(organization: org).count).to eq(2)
    ensure
      truncate_product_tables
    end
  end

  it "unmatched documents of the organization include Padaria Central" do
    insert_doc

    expect(organization.supporting_documents.unmatched.map(&:payee)).to include("Padaria Central")
  end

  it "confirm assigns Month 2026-05 on both documents" do
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    doc_a = insert_doc(payee: "Padaria A", amount: "100,00", photo: photo_named("a.jpg"))
    doc_b = insert_doc(payee: "Padaria B", amount: "120,00", photo: photo_named("b.jpg"))

    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ doc_a, doc_b ])

    expect(doc_a.reload.month.year_month).to eq("2026-05")
    expect(doc_b.reload.month.year_month).to eq("2026-05")
  end

  it "matched documents are absent from unmatched list" do
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    doc_a = insert_doc(payee: "Padaria A", amount: "100,00", photo: photo_named("a.jpg"))
    doc_b = insert_doc(payee: "Padaria B", amount: "120,00", photo: photo_named("b.jpg"))
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ doc_a, doc_b ])

    expect(organization.supporting_documents.unmatched).to be_empty
    expect(organization.supporting_documents.unmatched).not_to include(doc_a, doc_b)
  end

  it "update payee on matched document keeps the Match" do
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    document = insert_doc(amount: "220,00")
    match = Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])

    document.reload.apply(payee: "Mercado Silva")

    expect(document.errors).to be_empty
    expect(document.reload.payee).to eq("Mercado Silva")
    expect(Match.exists?(match.id)).to be true
    expect(payment.reload.match_id).to eq(match.id)
  end

  it "apply payee while document Month is closed leaves payee" do
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    document = insert_doc(amount: "220,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])
    month.update!(closed: true)

    document.reload.apply(payee: "Outro")

    expect(document.errors[:base]).to include("Mês fechado")
    expect(document.reload.payee).to eq("Padaria Central")
  end

  it "insert while a month is closed assigns no Month" do
    month, _statement = plant_month(organization)
    month.update!(closed: true)

    document = insert_doc(payee: "Novo Recibo")

    expect(document).to be_persisted
    expect(document.month_id).to be_nil
  end
end
