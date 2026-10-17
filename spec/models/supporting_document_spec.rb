require "rails_helper"

RSpec.describe SupportingDocument, type: :model do
  include ActiveSupport::Testing::TimeHelpers
  def organization
    @organization ||= create_organization!(name: "ONG")
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

  def nfe_chave
    "43260511222333000181550010000000011123456781"
  end

  def install_a1
    organization.install_sefaz_certificate(file: sefaz_pfx, passphrase: "passphrase-secreta")
  end

  def stub_xml_consulta(chave = nfe_chave, **nfe)
    SefazConsulta.current.set(chave, SefazConsulta::Xml.new(authorized_nfe_xml(**nfe)))
  end

  def stub_resumo_consulta(chave = nfe_chave, amount_cents: 15500, payee: "Padaria Central", document_on: Date.new(2026, 5, 11))
    SefazConsulta.current.set(chave, SefazConsulta::Resumo.new(amount_cents:, payee:, document_on:))
  end

  def ocr_photo(name, content_type: "image/png")
    bytes = Rails.root.join("spec/fixtures/files/ocr", name).binread
    upload_path(name, bytes, content_type)
  end

  it "insert recibo jpg persists one SupportingDocument for the organization" do
    doc = insert_doc

    expect(doc).to be_persisted
    expect(doc.organization).to eq(organization)
    expect(SupportingDocument.where(organization: organization).count).to eq(1)
  end

  it "insert recibo jpg persists 15500 typed photo no xml chave nil" do
    doc = insert_doc

    expect(doc).to be_persisted
    expect(SupportingDocument.where(organization: organization).count).to eq(1)
    expect(doc.kind).to eq("recibo")
    expect(doc.amount_cents).to be_a(Integer)
    expect(doc.amount_cents).to eq(15500)
    expect(doc.fields_origin).to eq("typed")
    expect(doc.photo).to be_attached
    expect(doc.xml).not_to be_attached
    expect(doc.chave).to be_nil
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
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: authorized_xml)

    expect(doc).to be_persisted
    expect(doc.xml).to be_attached
    expect(doc.photo).not_to be_attached
  end

  it "insert nota_fiscal with photo and xml attaches both" do
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg, xml: authorized_xml)

    expect(doc).not_to be_persisted
    expect(doc.errors[:base]).to include(SupportingDocument::NF_FILES)
  end

  it "rejects nota_fiscal without photo and xml" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: nil)

    expect(doc).not_to be_persisted
    expect(SupportingDocument.count).to eq(0)
  end

  it "insert authorized XML ignores typed 100,00 and keeps 15500" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: authorized_xml, amount: "100,00")

    expect(doc.amount_cents).to eq(15500)
    expect(doc.amount_cents).to be_a(Integer)
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
    doc = insert_doc(kind: "nota_fiscal", photo: photo_named("danfe.jpg"))
    doc.xml.attach(io: StringIO.new("<nfe><vNF>100.00</vNF></nfe>"), filename: "autorizada.xml", content_type: "application/xml")
    doc.apply(payee: "Mercado Silva")

    doc.reload
    expect(doc.photo.filename.to_s).to eq("danfe.jpg")
    expect(doc.xml.filename.to_s).to eq("autorizada.xml")
  end

  it "update photo replaces the photo blob" do
    doc = insert_doc(photo: photo_named("foto-antiga.jpg"))
    doc.apply(photo: photo_named("foto-nova.jpg"))

    expect(doc.errors[:base]).to include(SupportingDocument::PHOTO_LOCKED)
    expect(doc.reload.photo.filename.to_s).to eq("foto-antiga.jpg")
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

  it "apply kind recibo on xml-only nota_fiscal returns KIND_LOCKED" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: authorized_xml)
    doc.apply(kind: "recibo")

    expect(doc.errors[:base]).to include(SupportingDocument::KIND_LOCKED)
    expect(doc.reload.kind).to eq("nota_fiscal")
    expect(doc.xml).to be_attached
  end

  it "apply kind recibo with photo returns KIND_LOCKED and keeps xml" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: authorized_xml)
    doc.apply(kind: "recibo", photo: photo_named("recibo-novo.jpg"))

    expect(doc.errors[:base]).to include(SupportingDocument::KIND_LOCKED)
    doc.reload
    expect(doc.kind).to eq("nota_fiscal")
    expect(doc.xml).to be_attached
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
      org = create_organization!(name: "ONG")
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

  it "withdraw no-month document deletes the row and blobs" do
    document = insert_doc
    blob_id = document.photo.blob.id

    expect(document.withdraw).to eq(true)
    expect(SupportingDocument.find_by(id: document.id)).to be_nil
    expect(ActiveStorage::Blob.find_by(id: blob_id)).to be_nil
  end

  it "withdraw last member document destroys the Justification" do
    document = insert_doc
    justification = Justification.declare(
      organization: organization,
      account: account,
      amount: "155,00",
      supporting_document_ids: [ document.id ]
    )

    expect(document.withdraw).to eq(true)
    expect(Justification.find_by(id: justification.id)).to be_nil
  end

  it "withdraw month document is rejected" do
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 15500)
    document = insert_doc
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])

    expect(document.reload.withdraw).to eq(false)
    expect(document).to be_persisted
    expect(document.errors[:base]).to include(SupportingDocument::HAS_MONTH)
  end

  it "insert authorized XML persists 15500 Padaria Central 2026-05-11 and chave" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: authorized_xml, amount: nil, date: nil, payee: nil)

    expect(doc.amount_cents).to eq(15500)
    expect(doc.document_on).to eq(Date.new(2026, 5, 11))
    expect(doc.payee).to eq("Padaria Central")
    expect(doc.chave).to eq("43260511222333000181550010000000011123456781")
  end

  it "amount from vNF 155.00 is Integer 15500" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: authorized_xml, amount: nil, date: nil, payee: nil)

    expect(doc.amount_cents).to be_a(Integer)
    expect(doc.amount_cents).to eq(15500)
    expect(doc.amount_cents).not_to be_a(Float)
  end

  it "apply amount on uploaded XML is rejected" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: authorized_xml)
    doc.apply(amount: "200,00")

    expect(doc.errors[:base]).to include(SupportingDocument::LOCKED_FIELDS)
    expect(doc.reload.amount_cents).to eq(15500)
  end

  it "insert authorized XML persists 15500 uploaded_xml blob and apply 200,00 keeps 15500" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: authorized_xml, amount: nil, date: nil, payee: nil)

    expect(doc.amount_cents).to eq(15500)
    expect(doc.document_on).to eq(Date.new(2026, 5, 11))
    expect(doc.payee).to eq("Padaria Central")
    expect(doc.chave).to eq(nfe_chave)
    expect(doc.fields_origin).to eq("uploaded_xml")
    expect(doc.xml).to be_attached
    doc.apply(amount: "200,00")
    expect(doc.errors[:base]).to include("Valor, data e favorecido vêm da nota e não podem ser alterados")
    expect(doc.reload.amount_cents).to eq(15500)
  end

  it "apply payee on uploaded XML is rejected" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: authorized_xml)
    doc.apply(payee: "Mercado Silva")

    expect(doc.errors[:base]).to include(SupportingDocument::LOCKED_FIELDS)
    expect(doc.reload.payee).to eq("Padaria Central")
  end

  it "apply date on uploaded XML is rejected" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: authorized_xml)
    doc.apply(date: "2026-06-01")

    expect(doc.errors[:base]).to include(SupportingDocument::LOCKED_FIELDS)
    expect(doc.reload.document_on).to eq(Date.new(2026, 5, 11))
  end

  it "apply observation on uploaded XML persists" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: authorized_xml)
    doc.apply(observation: "pago em dinheiro")

    expect(doc.errors).to be_empty
    expect(doc.reload.observation).to eq("pago em dinheiro")
  end

  it "insert malformed XML persists none" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: xml_file("nota.xml", "<nfe><"), amount: "155,00", date: "2026-05-11", payee: "Padaria Central")

    expect(doc).not_to be_persisted
    expect(doc.errors[:base]).to include(SupportingDocument::XML_UNREADABLE)
    expect(SupportingDocument.count).to eq(0)
  end

  it "insert XML without ICMSTot vNF persists none" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: xml_with_vnf, amount: "155,00")

    expect(doc).not_to be_persisted
    expect(doc.errors[:base]).to include(SupportingDocument::XML_UNREADABLE)
    expect(SupportingDocument.count).to eq(0)
  end

  it "apply payee on pre-task XML blob persists Mercado Silva" do
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg)
    doc.xml.attach(io: StringIO.new("<nfe><vNF>100.00</vNF></nfe>"), filename: "nota.xml", content_type: "application/xml")
    doc.update_column(:fields_origin, nil)
    doc.apply(payee: "Mercado Silva")

    expect(doc.errors).to be_empty
    expect(doc.reload.payee).to eq("Mercado Silva")
    expect(doc.amount_cents).to eq(15500)
  end

  it "insert recibo then apply payee Mercado Silva persists" do
    doc = insert_doc
    doc.apply(payee: "Mercado Silva")

    expect(doc.reload.payee).to eq("Mercado Silva")
  end

  it "insert typed nota_fiscal photo then apply payee persists" do
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg, xml: nil)
    doc.apply(payee: "Mercado Silva")

    expect(doc.reload.payee).to eq("Mercado Silva")
    expect(doc.amount_cents).to eq(15500)
  end

  it "insert XML dhEmi 2026-05-11T23:30:00-03:00 stores document_on 2026-05-11" do
    doc = insert_doc(
      kind: "nota_fiscal",
      photo: nil,
      xml: authorized_xml(dhemi: "2026-05-11T23:30:00-03:00"),
      amount: nil,
      date: nil,
      payee: nil
    )

    expect(doc.document_on).to eq(Date.new(2026, 5, 11))
  end

  it "insert chave with consulta XML persists 15500 and attaches xml" do
    install_a1
    stub_xml_consulta
    doc = insert_doc(kind: "nota_fiscal", xml: nil, amount: nil, date: nil, payee: nil, chave: nfe_chave)

    expect(doc.amount_cents).to eq(15500)
    expect(doc.document_on).to eq(Date.new(2026, 5, 11))
    expect(doc.payee).to eq("Padaria Central")
    expect(doc.xml).to be_attached
    expect(doc.chave).to eq(nfe_chave)
  end

  it "insert chave with resumo persists fields without xml and locks amount" do
    install_a1
    stub_resumo_consulta
    doc = insert_doc(kind: "nota_fiscal", xml: nil, amount: nil, date: nil, payee: nil, chave: nfe_chave)

    expect(doc.amount_cents).to eq(15500)
    expect(doc.payee).to eq("Padaria Central")
    expect(doc.xml).not_to be_attached
    expect(doc.photo).to be_attached
    doc.apply(amount: "200,00")
    expect(doc.errors[:base]).to include(SupportingDocument::LOCKED_FIELDS)
  end

  it "insert chave resumo without files persists none" do
    install_a1
    stub_resumo_consulta
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: nil, amount: nil, date: nil, payee: nil, chave: nfe_chave)

    expect(doc).not_to be_persisted
    expect(doc.errors[:base]).to include(SupportingDocument::NF_FILES)
  end

  it "insert chave consulta XML without files attaches xml" do
    install_a1
    stub_xml_consulta
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: nil, amount: nil, date: nil, payee: nil, chave: nfe_chave)

    expect(doc).to be_persisted
    expect(doc.xml).to be_attached
    expect(doc.amount_cents).to eq(15500)
  end

  it "insert chave without certificate stays typed" do
    doc = insert_doc(kind: "nota_fiscal", xml: nil, chave: nfe_chave)
    doc.apply(payee: "Mercado Silva")

    expect(doc.reload.payee).to eq("Mercado Silva")
    expect(doc.amount_cents).to eq(15500)
  end

  it "insert chave with expired certificate stays typed" do
    travel_to Date.new(2026, 5, 11) do
      organization.install_sefaz_certificate(
        file: sefaz_pfx(not_after: Date.new(2026, 5, 11), name: "exp.pfx"),
        passphrase: "passphrase-secreta"
      )
    end
    travel_to Date.new(2026, 5, 12) do
      stub_xml_consulta
      doc = insert_doc(kind: "nota_fiscal", xml: nil, chave: nfe_chave)
      doc.apply(payee: "Mercado Silva")
      expect(doc.reload.payee).to eq("Mercado Silva")
    end
  end

  it "insert chave after certificate removed stays typed" do
    install_a1
    organization.remove_sefaz_certificate
    stub_xml_consulta
    doc = insert_doc(kind: "nota_fiscal", xml: nil, chave: nfe_chave)
    doc.apply(payee: "Mercado Silva")

    expect(doc.reload.payee).to eq("Mercado Silva")
  end

  it "insert chave when consulta errors stays typed" do
    install_a1
    SefazConsulta.current.set(nfe_chave, SefazConsulta::Error.new)
    doc = insert_doc(kind: "nota_fiscal", xml: nil, chave: nfe_chave)
    doc.apply(payee: "Mercado Silva")

    expect(doc.reload.payee).to eq("Mercado Silva")
  end

  it "insert chave when consulta errors without typed fields persists none" do
    install_a1
    SefazConsulta.current.set(nfe_chave, SefazConsulta::Error.new)
    doc = insert_doc(kind: "nota_fiscal", xml: nil, amount: nil, date: nil, payee: nil, chave: nfe_chave)

    expect(doc).not_to be_persisted
    expect(doc.errors[:base]).to include(SupportingDocument::MISSING_FIELDS)
  end

  it "insert chave when consulta not found or window-expired stays typed" do
    install_a1
    [ SefazConsulta::NotFound.new, SefazConsulta::WindowExpired.new ].each do |result|
      SefazConsulta.reset!
      SefazConsulta.current.set(nfe_chave, result)
      doc = insert_doc(kind: "nota_fiscal", xml: nil, chave: nfe_chave, payee: "Padaria Central")
      doc.apply(payee: "Mercado Silva")
      expect(doc.reload.payee).to eq("Mercado Silva")
      expect(doc.fields_origin).not_to eq(SupportingDocument::ORIGIN_IDENTIFIED)
      doc.destroy
    end
  end

  it "insert dotted chave stores 44 digits" do
    install_a1
    stub_xml_consulta
    doc = insert_doc(
      kind: "nota_fiscal",
      xml: nil,
      amount: nil,
      date: nil,
      payee: nil,
      chave: "4326.0511.2223.3300.0181.5500.1000.0000.0111.2345.6781"
    )

    expect(doc.chave).to eq(nfe_chave)
    expect(doc.xml).to be_attached
  end

  it "insert chave not 44 digits persists none" do
    doc = insert_doc(kind: "nota_fiscal", xml: nil, chave: "123")

    expect(doc).not_to be_persisted
    expect(doc.errors[:base]).to include(SupportingDocument::CHAVE_DIGITS)
  end

  it "insert duplicate chave persists two SupportingDocuments" do
    install_a1
    stub_xml_consulta
    insert_doc(kind: "nota_fiscal", xml: nil, chave: nfe_chave, photo: photo_named("a.jpg"))
    insert_doc(kind: "nota_fiscal", xml: nil, chave: nfe_chave, photo: photo_named("b.jpg"))

    expect(SupportingDocument.where(organization: organization, chave: nfe_chave).count).to eq(2)
  end

  it "insert recibo with chave stores no chave" do
    install_a1
    stub_xml_consulta
    doc = insert_doc(chave: nfe_chave)
    doc.apply(payee: "Mercado Silva")

    expect(doc.reload.chave).to be_nil
    expect(doc.kind).to eq("recibo")
    expect(doc.xml).not_to be_attached
    expect(doc.payee).to eq("Mercado Silva")
  end

  it "insert uploaded XML wins over consulta vNF 100.00" do
    install_a1
    stub_xml_consulta(vnf: "100.00", emit: "Outro")
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: authorized_xml(vnf: "155.00"), chave: nfe_chave)

    expect(doc.amount_cents).to eq(15500)
  end

  it "apply chave on uploaded XML keeps 15500" do
    install_a1
    stub_xml_consulta(vnf: "100.00", emit: "Outro")
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: authorized_xml(vnf: "155.00"), chave: nfe_chave)
    doc.apply(kind: "nota_fiscal", chave: nfe_chave, observation: "ok")

    expect(doc.reload.amount_cents).to eq(15500)
    expect(doc.fields_origin).to eq(SupportingDocument::ORIGIN_UPLOADED_XML)
    expect(doc.payee).to eq("Padaria Central")
  end

  it "confirm identified SEFAZ on uploaded XML keeps 15500" do
    install_a1
    stub_xml_consulta(vnf: "100.00", emit: "Outro")
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: authorized_xml(vnf: "155.00"), chave: nfe_chave)

    expect(doc.confirm_identified_sefaz).to eq(false)
    expect(doc.errors[:base]).to include(SupportingDocument::LOCKED_FIELDS)
    expect(doc.reload.amount_cents).to eq(15500)
    expect(doc.fields_origin).to eq(SupportingDocument::ORIGIN_UPLOADED_XML)
  end

  it "apply kind recibo on locked nota returns KIND_LOCKED" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: authorized_xml)
    doc.apply(kind: "recibo")

    expect(doc.errors[:base]).to include(SupportingDocument::KIND_LOCKED)
    expect(doc.reload.kind).to eq("nota_fiscal")
    expect(doc.xml).to be_attached
  end

  it "apply kind nota_fiscal on recibo returns KIND_LOCKED" do
    install_a1
    stub_xml_consulta(vnf: "100.00", emit: "Mercado Silva", dhemi: "2026-05-12T10:00:00-03:00")
    doc = insert_doc
    doc.apply(kind: "nota_fiscal", chave: nfe_chave)

    expect(doc.errors[:base]).to include(SupportingDocument::KIND_LOCKED)
    expect(doc.reload.kind).to eq("recibo")
  end

  it "apply chave on typed nota keeps 15500" do
    install_a1
    stub_xml_consulta(vnf: "100.00")
    doc = insert_doc(kind: "nota_fiscal", xml: nil)
    doc.apply(chave: nfe_chave)

    expect(doc.reload.amount_cents).to eq(15500)
    expect(doc.sefaz_confirm_pending).to eq(true)
  end

  it "apply chave on typed nota keeps 15500 pending not identified" do
    install_a1
    stub_xml_consulta(vnf: "100.00")
    doc = insert_doc(kind: "nota_fiscal", xml: nil)
    doc.apply(chave: nfe_chave)

    expect(doc.reload.amount_cents).to eq(15500)
    expect(doc.sefaz_confirm_pending).to eq(true)
    expect(doc.fields_origin).not_to eq("identified")
  end

  it "apply observation on pending chave keeps sefaz_confirm_pending" do
    install_a1
    stub_xml_consulta(vnf: "100.00")
    doc = insert_doc(kind: "nota_fiscal", xml: nil)
    doc.apply(chave: nfe_chave)
    doc.apply(observation: "ok")

    expect(doc.reload.sefaz_confirm_pending).to eq(true)
    expect(doc.amount_cents).to eq(15500)
  end

  it "confirm identified SEFAZ persists 10000 and locks" do
    install_a1
    stub_xml_consulta(vnf: "100.00")
    doc = insert_doc(kind: "nota_fiscal", xml: nil)
    doc.apply(chave: nfe_chave)
    expect(doc.confirm_identified_sefaz).to eq(true)

    expect(doc.reload.amount_cents).to eq(10000)
    doc.apply(amount: "200,00")
    expect(doc.errors[:base]).to include(SupportingDocument::LOCKED_FIELDS)
  end

  it "confirm identified SEFAZ persists 10000 identified without photo pipeline" do
    install_a1
    stub_xml_consulta(vnf: "100.00")
    doc = insert_doc(kind: "nota_fiscal", xml: nil)
    doc.apply(chave: nfe_chave)
    expect(PhotoSymbols.current).not_to receive(:scan)
    expect(PhotoFields.current).not_to receive(:read)
    expect(PublicNfceConsulta.current).not_to receive(:fetch)

    expect(doc.confirm_identified_sefaz).to eq(true)

    expect(doc.reload.amount_cents).to eq(10000)
    expect(doc.fields_origin).to eq("identified")
    expect(doc.sefaz_confirm_pending).to eq(false)
  end

  it "confirm identified SEFAZ from resumo persists 10000 and locks" do
    install_a1
    stub_resumo_consulta(amount_cents: 10000, payee: "Mercado Silva", document_on: Date.new(2026, 5, 12))
    doc = insert_doc(kind: "nota_fiscal", xml: nil)
    doc.apply(chave: nfe_chave)
    expect(doc.confirm_identified_sefaz).to eq(true)

    doc.reload
    expect(doc.amount_cents).to eq(10000)
    expect(doc.payee).to eq("Mercado Silva")
    expect(doc.document_on).to eq(Date.new(2026, 5, 12))
    expect(doc.xml).not_to be_attached
    doc.apply(amount: "200,00")
    expect(doc.errors[:base]).to include(SupportingDocument::LOCKED_FIELDS)
  end

  it "confirm identified SEFAZ with blank chave keeps 15500 editable" do
    install_a1
    doc = insert_doc(kind: "nota_fiscal", xml: nil)

    expect(doc.confirm_identified_sefaz).to eq(false)
    expect(doc.reload.amount_cents).to eq(15500)
    doc.apply(payee: "Mercado Silva")
    expect(doc.reload.payee).to eq("Mercado Silva")
  end

  it "confirm identified SEFAZ when xml cannot be parsed keeps 15500 editable" do
    install_a1
    stub_xml_consulta(vnf: "100.00")
    doc = insert_doc(kind: "nota_fiscal", xml: nil)
    doc.apply(chave: nfe_chave)
    SefazConsulta.current.set(nfe_chave, SefazConsulta::Xml.new("<nfe>sem infNFe</nfe>"))

    expect(doc.confirm_identified_sefaz).to eq(false)
    expect(doc.reload.amount_cents).to eq(15500)
    doc.apply(payee: "Mercado Silva")
    expect(doc.reload.payee).to eq("Mercado Silva")
  end

  it "insert chave with stored certificate and blank wrap key stays typed" do
    install_a1
    stub_xml_consulta(vnf: "100.00")
    doc = with_env("SEFAZ_WRAP_KEY" => nil) do
      insert_doc(kind: "nota_fiscal", xml: nil, chave: nfe_chave)
    end

    expect(doc.amount_cents).to eq(15500)
    expect(doc.xml).not_to be_attached
    doc.apply(payee: "Mercado Silva")
    expect(doc.reload.payee).to eq("Mercado Silva")
  end

  it "confirm identified SEFAZ when consulta errors keeps 15500 editable" do
    install_a1
    stub_xml_consulta(vnf: "100.00")
    doc = insert_doc(kind: "nota_fiscal", xml: nil)
    doc.apply(chave: nfe_chave)
    SefazConsulta.current.set(nfe_chave, SefazConsulta::Error.new)

    expect(doc.confirm_identified_sefaz).to eq(false)
    expect(doc.reload.amount_cents).to eq(15500)
    doc.apply(payee: "Mercado Silva")
    expect(doc.reload.payee).to eq("Mercado Silva")
  end

  it "apply chave without certificate stores chave and keeps 15500" do
    doc = insert_doc(kind: "nota_fiscal", xml: nil)
    doc.apply(chave: nfe_chave)

    expect(doc.reload.chave).to eq(nfe_chave)
    expect(doc.amount_cents).to eq(15500)
    expect(doc.sefaz_confirm_pending).to eq(false)
  end

  it "confirm identified SEFAZ on already identified changes nothing" do
    install_a1
    stub_xml_consulta
    doc = insert_doc(kind: "nota_fiscal", xml: nil, amount: nil, date: nil, payee: nil, chave: nfe_chave)
    amount = doc.amount_cents
    payee = doc.payee
    date = doc.document_on

    expect(doc.confirm_identified_sefaz).to eq(true)
    expect(doc.reload.amount_cents).to eq(amount)
    expect(doc.payee).to eq(payee)
    expect(doc.document_on).to eq(date)
  end

  it "apply chave while month closed is rejected" do
    doc = insert_doc(kind: "nota_fiscal", xml: nil, amount: "220,00")
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ doc ])
    month.update!(closed: true)

    doc.reload.apply(chave: nfe_chave)

    expect(doc.errors[:base]).to include("Mês fechado")
    expect(doc.reload.chave).to be_nil
  end

  it "install A1 after typed chave leaves amount typed" do
    doc = insert_doc(kind: "nota_fiscal", xml: nil, chave: nfe_chave)
    install_a1
    stub_xml_consulta(vnf: "100.00")
    doc.apply(payee: "Mercado Silva")

    expect(doc.reload.amount_cents).to eq(15500)
    expect(doc.payee).to eq("Mercado Silva")
  end

  it "remove certificate leaves identified lock" do
    install_a1
    stub_xml_consulta
    doc = insert_doc(kind: "nota_fiscal", xml: nil, amount: nil, date: nil, payee: nil, chave: nfe_chave)
    organization.remove_sefaz_certificate
    doc.apply(amount: "200,00")

    expect(doc.errors[:base]).to include(SupportingDocument::LOCKED_FIELDS)
  end

  it "expired certificate leaves identified lock" do
    travel_to Date.new(2026, 5, 11) do
      organization.install_sefaz_certificate(
        file: sefaz_pfx(not_after: Date.new(2026, 5, 11), name: "exp.pfx"),
        passphrase: "passphrase-secreta"
      )
      stub_xml_consulta
      @doc = insert_doc(kind: "nota_fiscal", xml: nil, amount: nil, date: nil, payee: nil, chave: nfe_chave)
    end
    travel_to Date.new(2026, 5, 12) do
      @doc.apply(amount: "200,00")
      expect(@doc.errors[:base]).to include(SupportingDocument::LOCKED_FIELDS)
    end
  end

  it "return unmatched-in-package Padaria clears month_id" do
    month, _statement = plant_month(organization)
    document = insert_doc
    document.update!(month_id: month.id)

    document.return_to_no_month

    expect(document.errors).to be_empty
    expect(document.reload.month_id).to be_nil
  end

  it "return while Month closed keeps month_id" do
    month, _statement = plant_month(organization)
    document = insert_doc
    document.update!(month_id: month.id)
    month.update!(closed: true)

    document.return_to_no_month

    expect(document.errors[:base]).to include("Mês fechado")
    expect(document.reload.month_id).to eq(month.id)
  end

  it "insert photo chave with consulta XML persists 15500 and attaches xml" do
    stub_photo_symbols("danfe.jpg", chave: nfe_chave)
    install_a1
    stub_xml_consulta
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("danfe.jpg"), xml: nil, amount: nil, date: nil, payee: nil)

    expect(doc.amount_cents).to eq(15500)
    expect(doc.document_on).to eq(Date.new(2026, 5, 11))
    expect(doc.payee).to eq("Padaria Central")
    expect(doc.chave).to eq(nfe_chave)
    expect(doc.xml).to be_attached
  end

  it "insert photo chave with consulta XML persists 15500 identified xml not pending" do
    stub_photo_symbols("danfe.jpg", chave: nfe_chave)
    install_a1
    stub_xml_consulta
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("danfe.jpg"), xml: nil, amount: nil, date: nil, payee: nil)

    expect(doc.amount_cents).to eq(15500)
    expect(doc.chave).to eq(nfe_chave)
    expect(doc.fields_origin).to eq("identified")
    expect(doc.xml).to be_attached
    expect(doc.sefaz_confirm_pending).to eq(false)
  end

  it "insert Real photo OCR text is invoked at most once" do
    PhotoSymbols.current = PhotoSymbols::Real.new
    PhotoFields.current = PhotoFields::Real.new
    expect(PhotoOcr).to receive(:text).once.and_call_original

    doc = insert_doc(
      kind: "nota_fiscal",
      photo: ocr_photo("danfe_fields.png"),
      xml: nil,
      amount: nil,
      date: nil,
      payee: nil
    )

    expect(doc).to be_persisted
    expect(doc.amount_cents).to eq(15500)
  ensure
    PhotoSymbols.reset!
    PhotoFields.reset!
  end

  it "insert Real QR identified XML does not invoke PhotoOcr text" do
    PhotoSymbols.current = PhotoSymbols::Real.new
    install_a1
    stub_xml_consulta(nfce_chave)
    expect(PhotoOcr).not_to receive(:text)

    insert_doc(
      kind: "nota_fiscal",
      photo: ocr_photo("nfce_qr.jpg", content_type: "image/jpeg"),
      xml: nil,
      amount: nil,
      date: nil,
      payee: nil
    )
  ensure
    PhotoSymbols.reset!
  end

  it "insert apply confirm skip lookup when pkcs12 is nil and persist 15500" do
    allow(SefazConsulta.current).to receive(:lookup)
    doc = insert_doc(kind: "nota_fiscal", xml: nil, chave: nfe_chave)

    expect(doc.amount_cents).to eq(15500)
    doc.apply(payee: "Mercado Silva")
    expect(doc.reload.payee).to eq("Mercado Silva")
    doc.confirm_identified_sefaz
    expect(SefazConsulta.current).not_to have_received(:lookup)
  end

  it "insert lookup receives PKCS12 and 44-digit chave" do
    install_a1
    stub_xml_consulta
    allow(SefazConsulta.current).to receive(:lookup).and_call_original
    insert_doc(kind: "nota_fiscal", xml: nil, amount: nil, date: nil, payee: nil, chave: nfe_chave)

    expect(SefazConsulta.current).to have_received(:lookup).with(
      pkcs12: an_instance_of(OpenSSL::PKCS12),
      chave: a_string_matching(/\A\d{44}\z/)
    )
  end

  it "insert pdf photo chave with consulta XML persists chave and xml" do
    stub_photo_symbols("foto.pdf", chave: nfe_chave)
    install_a1
    stub_xml_consulta
    doc = insert_doc(kind: "nota_fiscal", photo: photo_with_ext("pdf"), xml: nil, amount: nil, date: nil, payee: nil)

    expect(doc.chave).to eq(nfe_chave)
    expect(doc.xml).to be_attached
    expect(doc.amount_cents).to eq(15500)
  end

  it "insert printed-digit chave with consulta XML persists 15500" do
    stub_photo_symbols("printed.jpg", chave: nfe_chave)
    install_a1
    stub_xml_consulta
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("printed.jpg"), xml: nil, amount: nil, date: nil, payee: nil)

    expect(doc.chave).to eq(nfe_chave)
    expect(doc.amount_cents).to eq(15500)
    expect(doc.xml).to be_attached
  end

  it "insert photo chave wins over typed chave" do
    stub_photo_symbols("danfe.jpg", chave: nfe_chave)
    install_a1
    stub_xml_consulta
    stub_xml_consulta(other_chave, vnf: "100.00")
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("danfe.jpg"), xml: nil, amount: nil, date: nil, payee: nil, chave: other_chave)

    expect(doc.chave).to eq(nfe_chave)
    expect(doc.amount_cents).to eq(15500)
  end

  it "insert non-44 photo decode uses typed chave" do
    stub_photo_symbols("bad.jpg", chave: "123")
    install_a1
    stub_xml_consulta
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("bad.jpg"), xml: nil, amount: nil, date: nil, payee: nil, chave: nfe_chave)

    expect(doc.chave).to eq(nfe_chave)
    expect(doc.xml).to be_attached
  end

  it "insert recibo ignores photo chave" do
    stub_photo_symbols("recibo.jpg", chave: nfe_chave)
    install_a1
    stub_xml_consulta
    doc = insert_doc
    doc.apply(payee: "Mercado Silva")

    expect(doc.kind).to eq("recibo")
    expect(doc.chave).to be_nil
    expect(doc.xml).not_to be_attached
    expect(doc.reload.payee).to eq("Mercado Silva")
  end

  it "insert empty kind photo chave persists nota_fiscal" do
    stub_photo_symbols("recibo.jpg", chave: nfe_chave)
    doc = insert_doc(kind: "")

    expect(SupportingDocument.where(organization: organization).count).to eq(1)
    expect(doc.kind).to eq("nota_fiscal")
    expect(doc.chave).to eq(nfe_chave)
  end

  it "insert empty kind photo miss persists recibo" do
    stub_photo_symbols("recibo.jpg", chave: nil, qr_url: nil)
    doc = insert_doc(kind: "")

    expect(SupportingDocument.where(organization: organization).count).to eq(1)
    expect(doc.kind).to eq("recibo")
    expect(doc.chave).to be_nil
    expect(doc.xml).not_to be_attached
  end

  it "insert empty kind XML persists nota_fiscal uploaded_xml" do
    doc = insert_doc(kind: "", photo: nil, xml: authorized_xml)

    expect(doc.kind).to eq("nota_fiscal")
    expect(doc.chave).to eq(nfe_chave)
    expect(doc.amount_cents).to eq(15500)
    expect(doc.fields_origin).to eq("uploaded_xml")
  end

  it "insert empty kind XML chave wins over photo chave" do
    stub_photo_symbols("danfe.jpg", chave: other_chave)
    doc = insert_doc(kind: "", photo: photo_jpg("danfe.jpg"), xml: authorized_xml)

    expect(doc).not_to be_persisted
    expect(doc.errors[:base]).to include(SupportingDocument::NF_FILES)
  end

  it "insert empty kind photo QR persists nota_fiscal" do
    stub_photo_symbols("recibo.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    doc = insert_doc(kind: "")

    expect(doc.kind).to eq("nota_fiscal")
    expect(doc.chave).to eq(nfce_chave)
  end

  it "insert empty kind photo QR without chave persists nota_fiscal" do
    stub_photo_symbols("recibo.jpg", chave: nil, qr_url: nfce_qr_url)
    doc = insert_doc(kind: "")

    expect(doc.kind).to eq("nota_fiscal")
  end

  it "insert empty kind without file is BAD_KIND" do
    doc = insert_doc(kind: "", photo: nil, xml: nil)

    expect(doc).not_to be_persisted
    expect(SupportingDocument.where(organization: organization).count).to eq(0)
    expect(doc.errors[:base]).to include(SupportingDocument::NF_FILES)
  end

  it "insert kind recibo keeps recibo when photo has chave" do
    stub_photo_symbols("recibo.jpg", chave: nfe_chave)
    doc = insert_doc(kind: "recibo")

    expect(doc.kind).to eq("recibo")
    expect(doc.chave).to be_nil
    expect(doc.xml).not_to be_attached
  end

  it "insert kind nota_fiscal keeps nota_fiscal on photo miss" do
    stub_photo_symbols("recibo.jpg", chave: nil, qr_url: nil)
    doc = insert_doc(kind: "nota_fiscal", xml: nil)

    expect(doc.kind).to eq("nota_fiscal")
  end

  it "insert kind invoice with photo is BAD_KIND" do
    doc = insert_doc(kind: "invoice")

    expect(doc).not_to be_persisted
    expect(SupportingDocument.where(organization: organization).count).to eq(0)
    expect(doc.errors[:base]).to include(SupportingDocument::BAD_KIND)
  end

  it "insert empty kind photo fields origin photo stays correctable" do
    stub_photo_symbols("recibo.jpg", chave: nfe_chave)
    stub_photo_fields("recibo.jpg")
    doc = insert_doc(kind: "", amount: nil, date: nil, payee: nil, xml: nil)
    doc.apply(payee: "Mercado Silva")

    expect(doc.kind).to eq("nota_fiscal")
    expect(doc.amount_cents).to eq(15500)
    expect(doc.document_on).to eq(Date.new(2026, 5, 11))
    expect(doc.fields_origin).to eq("photo")
    expect(doc.reload.payee).to eq("Mercado Silva")
  end

  it "insert empty kind photo miss keeps typed payee" do
    stub_photo_symbols("recibo.jpg", chave: nil, qr_url: nil)
    doc = insert_doc(kind: "")

    expect(doc.payee).to eq("Padaria Central")
    expect(doc.fields_origin).to eq("typed")
  end

  it "insert empty kind photo scans PhotoSymbols before persist" do
    photo = photo_jpg("recibo.jpg")
    expect(PhotoSymbols.current).to receive(:scan).with(
      hash_including(bytes: "jpeg-bytes", filename: "recibo.jpg")
    ).and_call_original

    doc = insert_doc(kind: "", photo: photo)

    expect(doc).to be_persisted
    expect(doc.errors[:base]).not_to include(SupportingDocument::BAD_KIND)
  end

  it "insert uploaded XML chave wins over photo chave" do
    stub_photo_symbols("danfe.jpg", chave: other_chave)
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: authorized_xml)

    expect(doc.amount_cents).to eq(15500)
    expect(doc.chave).to eq(nfe_chave)
  end

  it "insert photo chave without certificate stays typed-correctable" do
    stub_photo_symbols("danfe.jpg", chave: nfe_chave)
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("danfe.jpg"), xml: nil)
    doc.apply(payee: "Mercado Silva")

    expect(doc.chave).to eq(nfe_chave)
    expect(doc.reload.payee).to eq("Mercado Silva")
    expect(doc.amount_cents).to eq(15500)
  end

  it "insert photo chave when consulta errors stays typed" do
    stub_photo_symbols("danfe.jpg", chave: nfe_chave)
    install_a1
    SefazConsulta.current.set(nfe_chave, SefazConsulta::Error.new)
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("danfe.jpg"), xml: nil)
    doc.apply(payee: "Mercado Silva")

    expect(doc.reload.payee).to eq("Mercado Silva")
  end

  it "insert photo chave with resumo locks amount" do
    stub_photo_symbols("danfe.jpg", chave: nfe_chave)
    install_a1
    stub_resumo_consulta
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("danfe.jpg"), xml: nil, amount: nil, date: nil, payee: nil)

    expect(doc.amount_cents).to eq(15500)
    expect(doc.payee).to eq("Padaria Central")
    expect(doc.photo).to be_attached
    expect(doc.xml).not_to be_attached
    doc.apply(amount: "200,00")
    expect(doc.errors[:base]).to include(SupportingDocument::LOCKED_FIELDS)
  end

  it "insert NFC-e QR public consulta persists 15500 origin nfc_e_public" do
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    stub_public_fields(nfce_qr_url)
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("nfce.jpg"), xml: nil, amount: nil, date: nil, payee: nil)

    expect(doc.amount_cents).to eq(15500)
    expect(doc.document_on).to eq(Date.new(2026, 5, 11))
    expect(doc.payee).to eq("Padaria Central")
    expect(doc.fields_origin).to eq("nfc_e_public")
    expect(doc.xml).not_to be_attached
    doc.apply(amount: "200,00")
    expect(doc.amount_cents).to eq(20000)
    expect(doc.reload.fields_origin).to eq("nfc_e_public")
    expect(doc.xml).not_to be_attached
    expect(doc.chave).to eq(nfce_chave)
  end

  it "insert NFC-e QR public consulta with blank wrap key stays correctable" do
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    stub_public_fields(nfce_qr_url)
    install_a1
    stub_xml_consulta(nfce_chave, vnf: "100.00")
    doc = with_env("SEFAZ_WRAP_KEY" => nil) do
      insert_doc(kind: "nota_fiscal", photo: photo_jpg("nfce.jpg"), xml: nil, amount: nil, date: nil, payee: nil)
    end
    doc.apply(amount: "200,00")

    expect(doc.amount_cents).to eq(20000)
  end

  it "insert NFC-e QR public consulta with expired certificate stays correctable" do
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    stub_public_fields(nfce_qr_url)
    travel_to Date.new(2026, 5, 11) do
      organization.install_sefaz_certificate(
        file: sefaz_pfx(not_after: Date.new(2026, 5, 11), name: "exp.pfx"),
        passphrase: "passphrase-secreta"
      )
    end
    travel_to Date.new(2026, 5, 12) do
      stub_xml_consulta(nfce_chave, vnf: "100.00")
      doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("nfce.jpg"), xml: nil, amount: nil, date: nil, payee: nil)
      doc.apply(amount: "200,00")
      expect(doc.amount_cents).to eq(20000)
    end
  end

  it "insert NFC-e QR public consulta when identified errors stays correctable" do
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    stub_public_fields(nfce_qr_url)
    install_a1
    SefazConsulta.current.set(nfce_chave, SefazConsulta::Error.new)
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("nfce.jpg"), xml: nil, amount: nil, date: nil, payee: nil)
    doc.apply(amount: "200,00")

    expect(doc.amount_cents).to eq(20000)
  end

  it "insert NFC-e QR public consulta when identified not found stays correctable" do
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    stub_public_fields(nfce_qr_url)
    install_a1
    [ SefazConsulta::NotFound.new, SefazConsulta::WindowExpired.new ].each do |result|
      SefazConsulta.reset!
      PhotoSymbols.reset!
      PhotoFields.reset!
      PublicNfceConsulta.reset!
      stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
      stub_public_fields(nfce_qr_url)
      SefazConsulta.current.set(nfce_chave, result)
      doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("nfce.jpg"), xml: nil, amount: nil, date: nil, payee: nil)
      doc.apply(amount: "200,00")
      expect(doc.amount_cents).to eq(20000)
      doc.destroy
    end
  end

  it "insert NFC-e QR identified XML locks and skips public" do
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    stub_public_fields(nfce_qr_url, amount_cents: 20000, payee: "Mercado Silva")
    install_a1
    stub_xml_consulta(nfce_chave)
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("nfce.jpg"), xml: nil, amount: nil, date: nil, payee: nil)
    doc.apply(amount: "200,00")

    expect(doc.amount_cents).to eq(15500)
    expect(doc.xml).to be_attached
    expect(doc.errors[:base]).to include(SupportingDocument::LOCKED_FIELDS)
  end

  it "insert CODE-128 without QR URL keeps typed payee" do
    stub_photo_symbols("code128.jpg", chave: nfe_chave)
    stub_public_fields("https://www.sefaz.rs.gov.br/anywhere", payee: "Mercado Silva")
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("code128.jpg"), xml: nil)

    expect(doc.payee).to eq("Padaria Central")
  end

  it "insert QR 127.0.0.1 keeps typed payee and no xml" do
    stub_photo_symbols("ssrf.jpg", chave: nfe_chave, qr_url: "http://127.0.0.1/nfce")
    stub_public_fields("http://127.0.0.1/nfce", payee: "Mercado Silva")
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("ssrf.jpg"), xml: nil)

    expect(doc.payee).to eq("Padaria Central")
    expect(doc.xml).not_to be_attached
  end

  it "insert QR example.com keeps typed payee and no xml" do
    stub_photo_symbols("ex.jpg", chave: nfe_chave, qr_url: "https://example.com/nfce")
    stub_public_fields("https://example.com/nfce", payee: "Mercado Silva")
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("ex.jpg"), xml: nil)

    expect(doc.payee).to eq("Padaria Central")
    expect(doc.xml).not_to be_attached
  end

  it "insert NFC-e QR when public consulta errors keeps typed payee" do
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    PublicNfceConsulta.current.set(nfce_qr_url, PublicNfceConsulta::Error.new)
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("nfce.jpg"), xml: nil)

    expect(doc.payee).to eq("Padaria Central")
  end

  it "insert NFC-e QR public partial three keeps typed payee" do
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    PublicNfceConsulta.current.set(
      nfce_qr_url,
      PublicNfceConsulta::Fields.new(amount_cents: 15500, payee: nil, document_on: nil)
    )
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("nfce.jpg"), xml: nil)

    expect(doc.payee).to eq("Padaria Central")
  end

  it "insert NFC-e QR public consulta payee is emitente" do
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    stub_public_fields(nfce_qr_url)
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("nfce.jpg"), xml: nil, amount: nil, date: nil, payee: nil)

    expect(doc.payee).to eq("Padaria Central")
    expect(doc.payee).not_to eq("ONG Destinataria")
  end

  it "insert photo field reading persists 15500 origin photo" do
    stub_photo_fields("fields.jpg")
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("fields.jpg"), xml: nil, amount: nil, date: nil, payee: nil)

    expect(doc.amount_cents).to eq(15500)
    expect(doc.document_on).to eq(Date.new(2026, 5, 11))
    expect(doc.payee).to eq("Padaria Central")
    expect(doc.fields_origin).to eq("photo")
    doc.apply(payee: "Mercado Silva")
    expect(doc.reload.payee).to eq("Mercado Silva")
    expect(doc.fields_origin).to eq("photo")
  end

  it "insert CODE-128 when identified errors uses field reading" do
    stub_photo_symbols("code128.jpg", chave: nfe_chave)
    stub_photo_fields("code128.jpg")
    install_a1
    SefazConsulta.current.set(nfe_chave, SefazConsulta::Error.new)
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("code128.jpg"), xml: nil, amount: nil, date: nil, payee: nil)
    doc.apply(payee: "Mercado Silva")

    expect(doc.amount_cents).to eq(15500)
    expect(doc.reload.payee).to eq("Mercado Silva")
  end

  it "insert NFC-e QR when public errors uses field reading" do
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    PublicNfceConsulta.current.set(nfce_qr_url, PublicNfceConsulta::Error.new)
    stub_photo_fields("nfce.jpg")
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("nfce.jpg"), xml: nil, amount: nil, date: nil, payee: nil)
    doc.apply(payee: "Mercado Silva")

    expect(doc.amount_cents).to eq(15500)
    expect(doc.reload.payee).to eq("Mercado Silva")
  end

  it "insert photo field reading partial three uses typed" do
    PhotoFields.current.set(
      "partial.jpg",
      amount_cents: 15500,
      document_on: nil,
      payee: nil
    )
    doc = insert_doc(
      kind: "nota_fiscal",
      photo: photo_jpg("partial.jpg"),
      xml: nil,
      amount: "100,00",
      date: "2026-05-11",
      payee: "Padaria Central"
    )

    expect(doc.amount_cents).to eq(10000)
    expect(doc.payee).to eq("Padaria Central")
  end

  it "insert nota photo with all extracts missing persists none" do
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("empty.jpg"), xml: nil, amount: nil, date: nil, payee: nil)

    expect(doc).not_to be_persisted
    expect(doc.errors[:base]).to include(SupportingDocument::MISSING_FIELDS)
    expect(SupportingDocument.count).to eq(0)
  end

  it "insert recibo ignores photo field reading" do
    stub_photo_fields("recibo.jpg", payee: "Mercado Silva")
    doc = insert_doc

    expect(doc.payee).to eq("Padaria Central")
  end

  it "insert photo field reading wins over typed payee" do
    stub_photo_fields("fields.jpg")
    doc = insert_doc(
      kind: "nota_fiscal",
      photo: photo_jpg("fields.jpg"),
      xml: nil,
      amount: "155,00",
      date: "2026-05-11",
      payee: "Mercado Silva"
    )

    expect(doc.payee).to eq("Padaria Central")
  end

  it "insert unreadable XML does not use photo field reading" do
    stub_photo_fields("danfe.jpg")
    doc = insert_doc(
      kind: "nota_fiscal",
      photo: nil,
      xml: xml_file("nota.xml", "<nfe><"),
      amount: nil,
      date: nil,
      payee: nil
    )

    expect(doc).not_to be_persisted
    expect(doc.errors[:base]).to include(SupportingDocument::XML_UNREADABLE)
    expect(SupportingDocument.count).to eq(0)
  end

  it "apply chave on photo-filled nota keeps 15500 pending confirm" do
    stub_photo_fields("fields.jpg")
    install_a1
    stub_xml_consulta(vnf: "100.00")
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("fields.jpg"), xml: nil, amount: nil, date: nil, payee: nil)
    doc.apply(chave: nfe_chave)

    expect(doc.reload.amount_cents).to eq(15500)
    expect(doc.sefaz_confirm_pending).to eq(true)
  end

  it "confirm identified SEFAZ on photo-filled nota locks 10000" do
    stub_photo_fields("fields.jpg")
    install_a1
    stub_xml_consulta(vnf: "100.00")
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("fields.jpg"), xml: nil, amount: nil, date: nil, payee: nil)
    doc.apply(chave: nfe_chave)
    expect(doc.confirm_identified_sefaz).to eq(true)

    expect(doc.reload.amount_cents).to eq(10000)
    doc.apply(amount: "200,00")
    expect(doc.errors[:base]).to include(SupportingDocument::LOCKED_FIELDS)
  end

  it "apply chave on public-filled nota keeps 15500 pending confirm" do
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    stub_public_fields(nfce_qr_url)
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("nfce.jpg"), xml: nil, amount: nil, date: nil, payee: nil)
    install_a1
    stub_xml_consulta(nfce_chave, vnf: "100.00")
    doc.apply(chave: nfce_chave)

    expect(doc.reload.amount_cents).to eq(15500)
    expect(doc.sefaz_confirm_pending).to eq(true)
  end

  it "confirm identified SEFAZ on public-filled nota locks 10000" do
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    stub_public_fields(nfce_qr_url)
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("nfce.jpg"), xml: nil, amount: nil, date: nil, payee: nil)
    install_a1
    stub_xml_consulta(nfce_chave, vnf: "100.00")
    doc.apply(chave: nfce_chave)
    expect(doc.confirm_identified_sefaz).to eq(true)

    expect(doc.reload.amount_cents).to eq(10000)
    doc.apply(amount: "200,00")
    expect(doc.errors[:base]).to include(SupportingDocument::LOCKED_FIELDS)
  end

  it "apply kind nota_fiscal on recibo with photo chave returns KIND_LOCKED" do
    stub_photo_symbols("recibo.jpg", chave: nfe_chave)
    install_a1
    stub_xml_consulta(vnf: "100.00", emit: "Mercado Silva", dhemi: "2026-05-12T10:00:00-03:00")
    doc = insert_doc
    doc.apply(kind: "nota_fiscal")

    expect(doc.errors[:base]).to include(SupportingDocument::KIND_LOCKED)
    expect(doc.reload.kind).to eq("recibo")
  end

  it "apply kind recibo on photo-filled nota returns KIND_LOCKED" do
    stub_photo_fields("fields.jpg")
    stub_photo_symbols("fields.jpg", chave: nfe_chave)
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("fields.jpg"), xml: nil, amount: nil, date: nil, payee: nil)
    doc.apply(kind: "recibo")

    expect(doc.errors[:base]).to include(SupportingDocument::KIND_LOCKED)
    expect(doc.reload.kind).to eq("nota_fiscal")
  end

  it "install A1 after photo-filled chave leaves amount" do
    stub_photo_fields("fields.jpg")
    stub_photo_symbols("fields.jpg", chave: nfe_chave)
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("fields.jpg"), xml: nil, amount: nil, date: nil, payee: nil)
    install_a1
    stub_xml_consulta(vnf: "100.00")
    doc.apply(payee: "Mercado Silva")

    expect(doc.reload.amount_cents).to eq(15500)
    expect(doc.payee).to eq("Mercado Silva")
  end

  it "apply chave on closed-month photo-filled document is rejected" do
    stub_photo_fields("fields.jpg")
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("fields.jpg"), xml: nil, amount: nil, date: nil, payee: nil)
    month, _statement = plant_month(organization)
    doc.update!(month_id: month.id)
    month.update!(closed: true)
    doc.apply(chave: nfe_chave)

    expect(doc.errors[:base]).to include(Month::CLOSED)
    expect(doc.reload.chave).to be_nil
  end

  it "insert duplicate photo chave persists two" do
    stub_photo_symbols("a.jpg", chave: nfe_chave)
    stub_photo_symbols("b.jpg", chave: nfe_chave)
    install_a1
    stub_xml_consulta
    first = insert_doc(kind: "nota_fiscal", photo: photo_named("a.jpg"), xml: nil, amount: nil, date: nil, payee: nil)
    second = insert_doc(kind: "nota_fiscal", photo: photo_named("b.jpg"), xml: nil, amount: nil, date: nil, payee: nil)

    expect(first).to be_persisted
    expect(second).to be_persisted
    expect(SupportingDocument.where(chave: nfe_chave).count).to eq(2)
  end

  it "amount from public consulta 155.00 is Integer 15500" do
    stub_photo_symbols("nfce.jpg", chave: nfce_chave, qr_url: nfce_qr_url)
    stub_public_fields(nfce_qr_url)
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("nfce.jpg"), xml: nil, amount: nil, date: nil, payee: nil)

    expect(doc.amount_cents).to be_a(Integer)
    expect(doc.amount_cents).to eq(15500)
  end

  it "amount from photo field reading 155.00 is Integer 15500" do
    stub_photo_fields("fields.jpg")
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("fields.jpg"), xml: nil, amount: nil, date: nil, payee: nil)

    expect(doc.amount_cents).to be_a(Integer)
    expect(doc.amount_cents).to eq(15500)
  end

  it "confirm identified SEFAZ on photo-filled nota when consulta errors keeps 15500 editable" do
    stub_photo_fields("fields.jpg")
    install_a1
    stub_xml_consulta(vnf: "100.00")
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg("fields.jpg"), xml: nil, amount: nil, date: nil, payee: nil)
    doc.apply(chave: nfe_chave)
    SefazConsulta.current.set(nfe_chave, SefazConsulta::Error.new)
    expect(doc.confirm_identified_sefaz).to eq(false)

    expect(doc.reload.amount_cents).to eq(15500)
    doc.apply(payee: "Mercado Silva")
    expect(doc.reload.payee).to eq("Mercado Silva")
  end

  describe "return during re-close" do
    self.use_transactional_tests = false
    self.use_transactional_tests = false

    it "return during re-close write keeps month_id" do
      truncate_product_tables
      org = create_organization!(
        name: "ONG Norte",
        accountant_presentation_name: "Maria Contadora",
        package_archive_folder_id: CloseHelpers::ARCHIVE_FOLDER_ID
      )
      coord = Account.create!(email: "coord@example.com", google_uid: "uid-coord")
      month, _statement = plant_month(org)
      document = plant_recibo(org, coord, payee: "Padaria Central", amount: "155,00")
      memory = PackageArchiveWriter::Memory.new
      Month.find(month.id).close_for_send(writer: memory, supporting_documents: [ document ])
      Month.find(month.id).reopen
      gate = Queue.new
      delay = Class.new do
        def initialize(inner, gate)
          @inner = inner
          @gate = gate
        end

        def replace_month_folder(**kwargs)
          @gate << :writing
          sleep 0.5
          @inner.replace_month_folder(**kwargs)
        end
      end.new(memory, gate)
      returned = nil

      closer = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Month.find(month.id).close_for_send(writer: delay)
        end
      end
      gate.pop
      ActiveRecord::Base.connection_pool.with_connection do
        returned = SupportingDocument.find(document.id)
        returned.return_to_no_month
      end
      closer.join

      expect(month.reload.closed?).to eq(true)
      expect(document.reload.month_id).to eq(month.id)
      expect(returned.errors[:base]).to include(Month::CLOSED)
      expect(memory.calls.last.fetch(:files).keys.grep(/padaria/)).not_to be_empty
    ensure
      truncate_product_tables
    end
  end

  it "apply refuses new photo when photo is already attached" do
    doc = insert_doc(photo: photo_named("foto-antiga.jpg"))
    doc.apply(photo: photo_named("foto-nova.jpg"))

    expect(doc.errors[:base]).to include(SupportingDocument::PHOTO_LOCKED)
    expect(doc.reload.photo.filename.to_s).to eq("foto-antiga.jpg")
  end

  it "apply refuses new XML when XML is already attached" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: authorized_xml)
    doc.apply(xml: xml_file("outra.xml"))

    expect(doc.errors[:base]).to include(SupportingDocument::XML_LOCKED)
    expect(doc.reload.xml.filename.to_s).to eq("autorizada.xml")
  end

  it "apply refuses kind change from nota_fiscal to recibo" do
    doc = insert_doc(kind: "nota_fiscal", photo: nil, xml: authorized_xml)
    doc.apply(kind: "recibo")

    expect(doc.errors[:base]).to include(SupportingDocument::KIND_LOCKED)
    expect(doc.reload.kind).to eq("nota_fiscal")
  end

  it "apply refuses kind change from recibo to nota_fiscal" do
    doc = insert_doc
    doc.apply(kind: "nota_fiscal")

    expect(doc.errors[:base]).to include(SupportingDocument::KIND_LOCKED)
    expect(doc.reload.kind).to eq("recibo")
  end

  it "insert infers kind from xml" do
    doc = insert_doc(kind: "", photo: nil, xml: authorized_xml)

    expect(doc.kind).to eq("nota_fiscal")
  end

  it "insert infers nota_fiscal from photo chave" do
    stub_photo_symbols("danfe.jpg", chave: nfe_chave)
    doc = insert_doc(kind: "", photo: photo_jpg("danfe.jpg"), xml: nil)

    expect(doc.kind).to eq("nota_fiscal")
    expect(doc.chave).to eq(nfe_chave)
  end

  it "insert infers nota_fiscal from identified XML" do
    install_a1
    stub_photo_symbols("danfe.jpg", chave: nfe_chave)
    stub_xml_consulta
    doc = insert_doc(kind: "", photo: photo_jpg("danfe.jpg"), xml: nil, amount: nil, date: nil, payee: nil)

    expect(doc.kind).to eq("nota_fiscal")
    expect(doc.fields_origin).to eq("identified")
  end

  it "insert infers nota_fiscal from public NFC-e" do
    stub_photo_symbols("nfce.jpg", chave: nil, qr_url: nfce_qr_url)
    stub_public_fields(nfce_qr_url)
    doc = insert_doc(kind: "", photo: photo_jpg("nfce.jpg"), xml: nil, amount: nil, date: nil, payee: nil)

    expect(doc.kind).to eq("nota_fiscal")
    expect(doc.fields_origin).to eq("nfc_e_public")
  end

  it "insert infers nota_fiscal from photo fields" do
    stub_photo_fields("danfe.jpg")
    doc = insert_doc(kind: "", photo: photo_jpg("danfe.jpg"), xml: nil, amount: nil, date: nil, payee: nil)

    expect(doc.kind).to eq("nota_fiscal")
    expect(doc.fields_origin).to eq("photo")
    expect(doc.amount_cents).to eq(15500)
  end

  it "insert infers recibo when photo extraction misses" do
    stub_photo_symbols("empty.jpg", chave: nil, qr_url: nil)
    doc = insert_doc(kind: "", photo: photo_jpg("empty.jpg"), xml: nil)

    expect(doc.kind).to eq("recibo")
    expect(doc.fields_origin).to eq("typed")
  end

  it "insert both photo and xml is xor" do
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg, xml: authorized_xml)

    expect(doc).not_to be_persisted
    expect(SupportingDocument.count).to eq(0)
    expect(doc.errors[:base]).to include("Envie a foto ou o XML")
  end

  it "insert neither photo nor xml is xor" do
    doc = insert_doc(kind: "", photo: nil, xml: nil)

    expect(doc).not_to be_persisted
    expect(SupportingDocument.count).to eq(0)
    expect(doc.errors[:base]).to include("Envie a foto ou o XML")
  end

  it "insert infers nota_fiscal from photo fields on image-PDF" do
    stub_photo_fields("foto.pdf")
    doc = insert_doc(kind: "", photo: photo_with_ext("pdf"), xml: nil, amount: nil, date: nil, payee: nil)

    expect(doc.kind).to eq("nota_fiscal")
    expect(doc.fields_origin).to eq("photo")
  end

  it "insert NFCom XML persists 25680 uploaded_xml blob" do
    doc = insert_doc(kind: "", photo: nil, xml: nfcom_file, amount: nil, date: nil, payee: nil)

    expect(doc).to be_persisted
    expect(doc.kind).to eq("nota_fiscal")
    expect(doc.amount_cents).to eq(25680)
    expect(doc.document_on).to eq(Date.new(2026, 6, 15))
    expect(doc.payee).to eq("EMPRESA TELECOM EXEMPLO S.A.")
    expect(doc.chave).to eq("27260611222333000181620010008920781028142810")
    expect(doc.fields_origin).to eq("uploaded_xml")
    expect(doc.xml).to be_attached
    expect(doc.photo).not_to be_attached
  end

  it "insert NF3e XML persists 18940 uploaded_xml blob" do
    doc = insert_doc(kind: "", photo: nil, xml: nf3e_file, amount: nil, date: nil, payee: nil)

    expect(doc.amount_cents).to eq(18940)
    expect(doc.document_on).to eq(Date.new(2026, 5, 20))
    expect(doc.payee).to eq("Companhia Energetica Exemplo")
    expect(doc.chave).to eq("27260611222333000181660010000008920781028142")
    expect(doc.fields_origin).to eq("uploaded_xml")
  end

  it "insert national NFSe XML persists 61000 uploaded_xml blob" do
    doc = insert_doc(kind: "", photo: nil, xml: nfse_file, amount: nil, date: nil, payee: nil)

    expect(doc.amount_cents).to eq(61000)
    expect(doc.document_on).to eq(Date.new(2026, 5, 6))
    expect(doc.payee).to eq("Contabilidade Exemplo Ltda")
    expect(doc.chave).to eq("41260511222333000181000000000000000000000000000001")
    expect(doc.fields_origin).to eq("uploaded_xml")
  end

  it "apply payee on NFCom uploaded XML keeps EMPRESA TELECOM" do
    doc = insert_doc(kind: "", photo: nil, xml: nfcom_file, amount: nil, date: nil, payee: nil)
    doc.apply(payee: "Mercado Silva")

    expect(doc.errors[:base]).to include(SupportingDocument::LOCKED_FIELDS)
    expect(doc.reload.payee).to eq("EMPRESA TELECOM EXEMPLO S.A.")
  end

  it "identify and insert of NFCom NF3e NFSe XML do not call SefazConsulta or PublicNfceConsulta" do
    [
      nfcom_file("nfcom-ports.xml"),
      nf3e_file("nf3e-ports.xml"),
      nfse_file("nfse-ports.xml")
    ].each do |upload|
      allow(SefazConsulta.current).to receive(:lookup)
      allow(PublicNfceConsulta.current).to receive(:fetch)

      preview = SupportingDocument.identify(organization: organization, file: upload)
      expect(preview.errors).to be_empty
      expect(SupportingDocument.count).to eq(0)
      expect(SefazConsulta.current).not_to have_received(:lookup)
      expect(PublicNfceConsulta.current).not_to have_received(:fetch)

      doc = insert_doc(kind: "", photo: nil, xml: upload, amount: nil, date: nil, payee: nil)
      expect(doc).to be_persisted
      expect(SefazConsulta.current).not_to have_received(:lookup)
      expect(PublicNfceConsulta.current).not_to have_received(:fetch)

      doc.withdraw
      RSpec::Mocks.space.reset_all
    end
  end

  it "insert CTe XML is XML_UNSUPPORTED persists none" do
    doc = insert_doc(kind: "", photo: nil, xml: cte_file, amount: nil, date: nil, payee: nil)

    expect(doc).not_to be_persisted
    expect(doc.errors[:base]).to include(SupportingDocument::XML_UNSUPPORTED)
    expect(SupportingDocument.count).to eq(0)
  end

  it "insert municipal NFSe XML is XML_UNSUPPORTED persists none" do
    doc = insert_doc(kind: "", photo: nil, xml: municipal_nfse_file, amount: nil, date: nil, payee: nil)

    expect(doc).not_to be_persisted
    expect(doc.errors[:base]).to include(SupportingDocument::XML_UNSUPPORTED)
    expect(SupportingDocument.count).to eq(0)
  end

  it "identify Real two-page PDF CODE-128 is nota_fiscal chave without persisting" do
    PhotoSymbols.current = PhotoSymbols::Real.new
    pdf = pdf_upload("nota.pdf", pngs_to_pdf(ocr_png("blank.png"), code128_png))

    preview = SupportingDocument.identify(organization: organization, file: pdf)

    expect(SupportingDocument.count).to eq(0)
    expect(preview.errors).to be_empty
    expect(preview.kind).to eq("nota_fiscal")
    expect(preview.chave).to eq(nfe_chave)
  ensure
    PhotoSymbols.reset!
  end

  it "apply xml on photo-only is XML_LOCKED" do
    doc = insert_doc(kind: "nota_fiscal", photo: photo_jpg, xml: nil)
    expect(doc.xml).not_to be_attached
    doc.apply(xml: authorized_xml)

    expect(doc.errors[:base]).to include(SupportingDocument::XML_LOCKED)
    expect(doc.reload.xml).not_to be_attached
  end
end
