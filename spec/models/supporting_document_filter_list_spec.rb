require "rails_helper"

RSpec.describe SupportingDocument, ".filter_list", type: :model do
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

  it "filter_list filters by payee substring case-insensitively and escapes wildcards" do
    padaria = insert_doc(payee: "Padaria Central")
    mercado = insert_doc(payee: "Mercado 100% Natural")

    expect(organization.supporting_documents.filter_list(q: "padaria")).to eq([ padaria ])
    expect(organization.supporting_documents.filter_list(q: "PADARIA")).to eq([ padaria ])
    expect(organization.supporting_documents.filter_list(q: "Inexistente")).to be_empty
    expect(organization.supporting_documents.filter_list(q: "100%")).to eq([ mercado ])
  end

  it "filter_list filters by valid kind and ignores unknown kind" do
    recibo = insert_doc(kind: "recibo", payee: "Papelaria Lume")
    nota = insert_doc(kind: "nota_fiscal", payee: "Padaria Central")

    expect(organization.supporting_documents.filter_list(kind: "recibo")).to eq([ recibo ])
    expect(organization.supporting_documents.filter_list(kind: "nota_fiscal")).to eq([ nota ])
    expect(organization.supporting_documents.filter_list(kind: "outro")).to match_array([ recibo, nota ])
  end

  it "filter_list filters by date_from and date_to inclusive and ignores invalid dates" do
    early = insert_doc(date: "2026-05-08", payee: "Doc 08")
    mid = insert_doc(date: "2026-05-10", payee: "Doc 10")
    late = insert_doc(date: "2026-05-12", payee: "Doc 12")
    after = insert_doc(date: "2026-05-13", payee: "Doc 13")

    expect(organization.supporting_documents.filter_list(date_from: "2026-05-10")).to eq([ after, late, mid ])
    expect(organization.supporting_documents.filter_list(date_to: "2026-05-12")).to eq([ late, mid, early ])
    expect(organization.supporting_documents.filter_list(date_from: "2026-05-10", date_to: "2026-05-12")).to eq([ late, mid ])
    expect(organization.supporting_documents.filter_list(date_from: "invalid", date_to: "not-a-date")).to eq([ after, late, mid, early ])
  end

  it "filter_list orders by date and amount ascending and descending" do
    d1 = insert_doc(date: "2026-05-08", amount: "320,00", payee: "Mercado")
    d2 = insert_doc(date: "2026-05-11", amount: "48,90", payee: "Papelaria")
    d3 = insert_doc(date: "2026-05-14", amount: "155,00", payee: "Padaria")

    expect(organization.supporting_documents.filter_list).to eq([ d3, d2, d1 ])
    expect(organization.supporting_documents.filter_list(sort: "date", dir: "asc")).to eq([ d1, d2, d3 ])
    expect(organization.supporting_documents.filter_list(sort: "amount", dir: "desc")).to eq([ d1, d3, d2 ])
    expect(organization.supporting_documents.filter_list(sort: "amount", dir: "asc")).to eq([ d2, d3, d1 ])
  end
end
