require "rails_helper"

RSpec.describe Month, type: :model do
  def organization
    @organization ||= Organization.create!(name: "ONG")
  end

  it "opens 2026-05 for the organization" do
    month = Month.open(organization: organization, year_month: "2026-05")

    expect(month).to be_persisted
    expect(month.year_month).to eq("2026-05")
    expect(month.organization).to eq(organization)
    expect(organization.months.where(year_month: "2026-05").count).to eq(1)
  end

  it "finds existing 2026-05 rather than creating a second" do
    first = Month.open(organization: organization, year_month: "2026-05")
    second = Month.open(organization: organization, year_month: "2026-05")

    expect(second).to eq(first)
    expect(organization.months.where(year_month: "2026-05").count).to eq(1)
  end

  it "rejects year_month 2026-13" do
    month = Month.open(organization: organization, year_month: "2026-13")

    expect(month).not_to be_persisted
    expect(organization.months.count).to eq(0)
  end

  describe "concurrent opens persist exactly one Month" do
    self.use_transactional_tests = false

    it "concurrent opens persist exactly one Month" do
      truncate_product_tables
      org = Organization.create!(name: "ONG")

      run_in_parallel(2) do
        Month.open(organization: org, year_month: "2026-05")
      rescue ActiveRecord::RecordNotUnique
        nil
      end

      expect(Month.where(organization: org, year_month: "2026-05").count).to eq(1)
    ensure
      truncate_product_tables
    end
  end

  describe "close and reopen" do
    def organization
      @organization ||= Organization.create!(
        name: "ONG Norte",
        accountant_presentation_name: "Maria Contadora",
        package_archive_folder_id: CloseHelpers::ARCHIVE_FOLDER_ID
      )
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

    def account
      @account ||= Account.create!(email: "coord@example.com", google_uid: "uid-month-close")
    end

    it "close with missing document 22000 cents does not close and does not write" do
      plant_payment(statement, 22000)
      calls = writer.calls.size

      month.close_for_send

      expect(month.errors[:base]).to include("Há documento faltante")
      expect(month.reload.closed?).to eq(false)
      expect(writer.calls.size).to eq(calls)
    end

    it "close with extra Doacao payment does not add Ha documento faltante" do
      kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")
      payment = plant_payment(statement, 22000)
      payment.mark_document_exception(extra_exception_kind_id: kind.id)

      month.close_for_send

      expect(month.errors[:base]).not_to include("Há documento faltante")
    end

    it "close with active account without statement does not close" do
      BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
      opened = Month.open(organization: organization, year_month: "2026-05")

      opened.close_for_send

      expect(opened.errors[:base]).to include("Importe o extrato de cada conta ativa")
      expect(opened.reload.closed?).to eq(false)
    end

    it "close without archive folder id does not close" do
      organization.update!(package_archive_folder_id: nil)

      month.close_for_send

      expect(month.errors[:base]).to include("Informe a pasta do arquivo do pacote")
      expect(month.reload.closed?).to eq(false)
    end

    it "close without accountant presentation name does not close" do
      organization.update!(accountant_presentation_name: nil)

      month.close_for_send

      expect(month.errors[:base]).to include("Cadastre o contador")
      expect(month.reload.closed?).to eq(false)
    end

    it "close ready month persists closed and writes once" do
      month.close_for_send

      expect(month.errors).to be_empty
      expect(month.reload.closed?).to eq(true)
      expect(writer.calls.size).to eq(1)
    end

    it "close when writer raises leaves Month open" do
      failing = Class.new do
        def replace_month_folder(**)
          raise PackageArchiveWriter::Error
        end
      end.new

      month.close_for_send(writer: failing)

      expect(month.errors[:base]).to include("Não foi possível gravar no arquivo do pacote")
      expect(month.reload.closed?).to eq(false)
    end

    it "close while already closed does not write" do
      month.close_for_send
      calls = writer.calls.size

      month.close_for_send

      expect(month.errors[:base]).to include("Mês fechado")
      expect(month.reload.closed?).to eq(true)
      expect(writer.calls.size).to eq(calls)
    end

    it "close ignores inactive account without statement" do
      inactive = BankAccount.create_for(organization: organization, name: "Conta Antiga", compe: "001")
      inactive.apply_from(active: false)

      month.close_for_send

      expect(month.errors).to be_empty
      expect(month.reload.closed?).to eq(true)
    end

    it "first close stores writer folder id on the Month" do
      month.close_for_send

      expect(month.reload.month_folder_id).to eq(writer.folders.keys.first)
    end

    it "second close reuses month_folder_id and does not create another 2026-05" do
      month.close_for_send
      folder_id = month.reload.month_folder_id
      month.reopen

      month.close_for_send

      expect(month.reload.month_folder_id).to eq(folder_id)
      expect(writer.folders.count { |_id, folder| folder[:name] == "2026-05" }).to eq(1)
    end

    it "reopen sets closed false and does not write" do
      month.close_for_send
      calls = writer.calls.size

      month.reopen

      expect(month.reload.closed?).to eq(false)
      expect(writer.calls.size).to eq(calls)
    end

    it "reopen keeps month_folder_id and does not destroy matches" do
      payment = plant_payment(statement, 22000)
      document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
      match = Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])
      month.close_for_send
      folder_id = month.reload.month_folder_id

      month.reopen

      expect(month.reload.month_folder_id).to eq(folder_id)
      expect(Match.exists?(match.id)).to eq(true)
    end

    it "reopen while open leaves closed false" do
      month.reopen

      expect(month.errors[:base]).to include("Mês aberto")
      expect(month.reload.closed?).to eq(false)
    end

    it "open 2026-05 persists closed false with no closing state" do
      opened = Month.open(organization: organization, year_month: "2026-05")

      expect(opened.closed?).to eq(false)
      expect(opened.closed).to eq(false)
      expect(Month.column_names).not_to include("status")
      expect(opened).not_to respond_to(:closing)
    end
  end

  describe "concurrent closes persist closed once and write once" do
    self.use_transactional_tests = false

    it "concurrent closes persist closed once and write once" do
      truncate_product_tables
      org = Organization.create!(
        name: "ONG Norte",
        accountant_presentation_name: "Maria Contadora",
        package_archive_folder_id: CloseHelpers::ARCHIVE_FOLDER_ID
      )
      month, _statement = plant_month(org)
      memory = PackageArchiveWriter::Memory.new

      run_in_parallel(2) do
        Month.find(month.id).close_for_send(writer: memory)
      end

      expect(month.reload.closed?).to eq(true)
      expect(memory.calls.size).to eq(1)
    ensure
      truncate_product_tables
    end
  end
end
