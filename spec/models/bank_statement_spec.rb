require "rails_helper"

RSpec.describe BankStatement, type: :model do
  def organization
    @organization ||= Organization.create!(name: "ONG")
  end

  def month
    @month ||= Month.open(organization: organization, year_month: "2026-05")
  end

  def bb_account
    @bb_account ||= BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
  end

  def pagseguro_account
    @pagseguro_account ||= BankAccount.create_for(organization: organization, name: "PagSeguro", compe: "290")
  end

  it "has_one_attached pdf and spreadsheet" do
    expect(BankStatement.reflect_on_attachment(:pdf)).to be_present
    expect(BankStatement.reflect_on_attachment(:spreadsheet)).to be_present
  end

  it "import BB xlsx persists one BankStatement for the month and account" do
    statement = BankStatement.import(month: month, bank_account: bb_account, pdf: statement_pdf, spreadsheet: bb_xlsx)

    expect(statement).to be_persisted
    expect(statement.month).to eq(month)
    expect(statement.bank_account).to eq(bb_account)
    expect(BankStatement.where(month: month, bank_account: bb_account).count).to eq(1)
  end

  it "BB May 2026 fixture yields 18 Inflows and 13 Payments" do
    statement = BankStatement.import(month: month, bank_account: bb_account, pdf: statement_pdf, spreadsheet: bb_xlsx)

    expect(statement.inflows.count).to eq(18)
    expect(statement.payments.count).to eq(13)
  end

  it "BB fixture tarifa is Payment 15500 cents on 2026-05-11" do
    statement = BankStatement.import(month: month, bank_account: bb_account, pdf: statement_pdf, spreadsheet: bb_xlsx)
    payment = statement.payments.find_by!(amount_cents: 15500)

    expect(payment.occurred_on).to eq(Date.new(2026, 5, 11))
    expect(payment.history).to include("Tarifa Pacote de Serviços")
  end

  it "BB fixture Pix Recebido is Inflow 6300 cents with detalhamento" do
    statement = BankStatement.import(month: month, bank_account: bb_account, pdf: statement_pdf, spreadsheet: bb_xlsx)
    inflow = statement.inflows.find_by!(amount_cents: 6300, occurred_on: Date.new(2026, 5, 4))

    expect(inflow.history).to eq("Pix - Recebido — 04/05 17:51 DIEGO OLIVEIRA VIEIRA")
  end

  it "BB fixture skips Saldo Anterior and S A L D O" do
    statement = BankStatement.import(month: month, bank_account: bb_account, pdf: statement_pdf, spreadsheet: bb_xlsx)
    expect(statement).to be_persisted

    histories = statement.inflows.pluck(:history) + statement.payments.pluck(:history)
    expect(histories).not_to be_empty
    expect(histories).not_to include("Saldo Anterior")
    expect(histories).not_to include("S A L D O")
    expect(histories.none? { |history| history.strip == "Saldo Anterior" || history.strip == "S A L D O" }).to be(true)
  end

  it "tarifa amount_cents is Integer 15500" do
    statement = BankStatement.import(month: month, bank_account: bb_account, pdf: statement_pdf, spreadsheet: bb_xlsx)
    payment = statement.payments.find_by!(amount_cents: 15500)

    expect(payment.amount_cents).to be_a(Integer)
    expect(payment.amount_cents).to eq(15500)
  end

  it "import attaches pdf and spreadsheet via Active Storage" do
    statement = BankStatement.import(month: month, bank_account: bb_account, pdf: statement_pdf, spreadsheet: bb_xlsx)

    expect(statement.pdf).to be_attached
    expect(statement.spreadsheet).to be_attached
    expect(statement.pdf.blob.service_name).to eq("test")
    expect(statement.spreadsheet.blob.service_name).to eq("test")
    expect(Rails.root.join("config/storage.yml").read).not_to match(/Drive/)
  end

  it "rejects import without spreadsheet" do
    statement = BankStatement.import(month: month, bank_account: bb_account, pdf: statement_pdf, spreadsheet: nil)

    expect(statement).not_to be_persisted
    expect(BankStatement.count).to eq(0)
  end

  it "rejects import without pdf" do
    statement = BankStatement.import(month: month, bank_account: bb_account, pdf: nil, spreadsheet: bb_xlsx)

    expect(statement).not_to be_persisted
    expect(BankStatement.count).to eq(0)
  end

  it "rejects BB xlsx whose headers are not the eleven names" do
    statement = BankStatement.import(month: month, bank_account: bb_account, pdf: statement_pdf, spreadsheet: scrambled_xlsx)

    expect(statement).not_to be_persisted
    expect(BankStatement.count).to eq(0)
  end

  it "import BB csv yields 18 Inflows and 13 Payments" do
    statement = BankStatement.import(month: month, bank_account: bb_account, pdf: statement_pdf, spreadsheet: bb_csv)

    expect(statement.inflows.count).to eq(18)
    expect(statement.payments.count).to eq(13)
  end

  it "PagSeguro May 2026 fixture yields 64 Inflows and 7 Payments" do
    statement = BankStatement.import(month: month, bank_account: pagseguro_account, pdf: pagseguro_pdf, spreadsheet: pagseguro_xlsx)

    expect(statement.inflows.count).to eq(64)
    expect(statement.payments.count).to eq(7)
  end

  it "PagSeguro fixture skips Saldo do dia" do
    statement = BankStatement.import(month: month, bank_account: pagseguro_account, pdf: pagseguro_pdf, spreadsheet: pagseguro_xlsx)
    histories = statement.inflows.pluck(:history) + statement.payments.pluck(:history)

    expect(histories.none? { |history| history.start_with?("Saldo do dia") }).to be(true)
  end

  it "PagSeguro Pix enviado is Payment 151240 cents on 2026-05-11" do
    statement = BankStatement.import(month: month, bank_account: pagseguro_account, pdf: pagseguro_pdf, spreadsheet: pagseguro_xlsx)
    payment = statement.payments.find_by!(amount_cents: 151240)

    expect(payment.occurred_on).to eq(Date.new(2026, 5, 11))
    expect(payment.history).to eq("Pix enviado — VITOR CASTRO FERREIRA")
  end

  it "PagSeguro rendimento is Inflow 2 cents on 2026-05-01" do
    statement = BankStatement.import(month: month, bank_account: pagseguro_account, pdf: pagseguro_pdf, spreadsheet: pagseguro_xlsx)
    inflow = statement.inflows.find_by!(amount_cents: 2, occurred_on: Date.new(2026, 5, 1))

    expect(inflow.history).to eq("Rendimento da conta — Rendimento líquido sobre dinheiro em conta")
  end

  it "replace keeps one BankStatement and only new movements" do
    BankStatement.import(month: month, bank_account: bb_account, pdf: statement_pdf, spreadsheet: bb_xlsx)
    statement = BankStatement.import(month: month, bank_account: bb_account, pdf: statement_pdf, spreadsheet: one_row_csv)

    expect(BankStatement.where(month: month, bank_account: bb_account).count).to eq(1)
    expect(statement.payments.count).to eq(1)
    expect(statement.inflows.count).to eq(0)
    expect(Payment.where("history LIKE ?", "%Tarifa Pacote de Serviços%")).to be_empty
    expect(statement.payments.first.history).to include("substituicao")
  end

  it "rejects COMPE 341" do
    itau = BankAccount.create_for(organization: organization, name: "Itaú", compe: "341")
    statement = BankStatement.import(month: month, bank_account: itau, pdf: statement_pdf, spreadsheet: bb_xlsx)

    expect(statement).not_to be_persisted
    expect(BankStatement.count).to eq(0)
  end

  it "rejects import for inactive BankAccount with no statement" do
    bb_account.apply_from(active: false)
    statement = BankStatement.import(month: month, bank_account: bb_account, pdf: statement_pdf, spreadsheet: bb_xlsx)

    expect(statement).not_to be_persisted
    expect(BankStatement.count).to eq(0)
  end

  it "rejects a file larger than 10485760 bytes" do
    statement = BankStatement.import(month: month, bank_account: bb_account, pdf: oversized_pdf, spreadsheet: bb_xlsx)

    expect(statement).not_to be_persisted
    expect(BankStatement.count).to eq(0)
  end

  it "rejects movement file extension ofx" do
    statement = BankStatement.import(month: month, bank_account: bb_account, pdf: statement_pdf, spreadsheet: ofx_file)

    expect(statement).not_to be_persisted
    expect(BankStatement.count).to eq(0)
  end

  it "rejects BB movement whose date is not in 2026-05" do
    statement = BankStatement.import(month: month, bank_account: bb_account, pdf: statement_pdf, spreadsheet: bb_csv_with_april_row)

    expect(statement).not_to be_persisted
    expect(BankStatement.count).to eq(0)
  end

  it "zero movements after skips still persist BankStatement" do
    statement = BankStatement.import(month: month, bank_account: bb_account, pdf: statement_pdf, spreadsheet: zero_row_csv)

    expect(statement).to be_persisted
    expect(statement.inflows.count).to eq(0)
    expect(statement.payments.count).to eq(0)
  end

  describe "concurrent imports persist exactly one BankStatement" do
    self.use_transactional_tests = false

    it "concurrent imports persist exactly one BankStatement" do
      truncate_product_tables
      org = Organization.create!(name: "ONG")
      opened = Month.open(organization: org, year_month: "2026-05")
      account = BankAccount.create_for(organization: org, name: "Conta Principal", compe: "001")

      run_in_parallel(2) do
        BankStatement.import(month: opened, bank_account: account, pdf: statement_pdf, spreadsheet: bb_xlsx)
      rescue ActiveRecord::RecordNotUnique
        nil
      end

      expect(BankStatement.where(month: opened, bank_account: account).count).to eq(1)
    ensure
      truncate_product_tables
    end
  end
end
