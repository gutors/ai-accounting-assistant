require "rails_helper"

RSpec.describe MonthPackage, type: :model do
  def organization
    @organization ||= create_organization!(name: "ONG Norte")
  end

  def account
    @account ||= Account.create!(email: "coord@example.com", google_uid: "uid-package")
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

  def package_files
    MonthPackage.files(month)
  end

  it "package files include resumo-2026-05.xlsx" do
    expect(package_files.keys).to include("resumo-2026-05.xlsx")
  end

  it "statement files are extratos/extrato-conta-principal.pdf and xlsx" do
    attach_statement_files(statement, spreadsheet: "extrato.xlsx")

    expect(package_files.keys).to include(
      "extratos/extrato-conta-principal.pdf",
      "extratos/extrato-conta-principal.xlsx"
    )
  end

  it "csv statement file is extratos/extrato-conta-principal.csv" do
    attach_statement_files(statement, spreadsheet: "extrato.csv")

    expect(package_files.keys).to include("extratos/extrato-conta-principal.csv")
    expect(package_files.keys).not_to include("extratos/extrato-conta-principal.xlsx")
  end

  it "recibo photo path is notas/recibo-2026-05-11-padaria-central-id.jpg" do
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])

    expect(package_files.keys).to include("notas/recibo-2026-05-11-padaria-central-#{document.id}.jpg")
  end

  it "nota photo and xml share notas/nota-2026-05-11-mercado-silva-id stem" do
    payment = plant_payment(statement, 22000)
    document = plant_nota(organization, account, payee: "Mercado Silva", amount: "220,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])
    stem = "notas/nota-2026-05-11-mercado-silva-#{document.id}"

    expect(package_files.keys).to include("#{stem}.jpg", "#{stem}.xml")
  end

  it "package files have no notas-sem-casamento prefix" do
    expect(package_files.keys.grep(/\Anotas-sem-casamento\//)).to eq([])
  end

  it "unmatched-in-package recibo path is notas-sem-casamento" do
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    document.update!(month_id: month.id)

    expect(package_files.keys).to include("notas-sem-casamento/recibo-2026-05-11-padaria-central-#{document.id}.jpg")
    expect(package_files.keys.grep(%r{\Anotas/.*#{document.id}})).to eq([])
  end

  it "matched Mercado stays under notas when Padaria is unmatched-in-package" do
    payment = plant_payment(statement, 22000)
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "220,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ mercado ])
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    padaria.update!(month_id: month.id)

    expect(package_files.keys).to include("notas/recibo-2026-05-11-mercado-silva-#{mercado.id}.jpg")
    expect(package_files.keys).to include("notas-sem-casamento/recibo-2026-05-11-padaria-central-#{padaria.id}.jpg")
  end
end
