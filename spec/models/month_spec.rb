require "rails_helper"

RSpec.describe Month, type: :model do
  def organization
    @organization ||= create_organization!(name: "ONG")
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

  it "open empty year_month adds Informe um mes valido and does not persist" do
    month = Month.open(organization: organization, year_month: "")

    expect(month).not_to be_persisted
    expect(month.errors[:base]).to include("Informe um mês válido")
    expect(organization.months.count).to eq(0)
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
      org = create_organization!(name: "ONG")

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
      @organization ||= create_organization!(
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

    it "close with Padaria assigns month_id after a successful write" do
      document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

      month.close_for_send(supporting_documents: [ document ])

      expect(month.errors).to be_empty
      expect(month.reload.closed?).to eq(true)
      document.reload
      expect(document.month_id).to eq(month.id)
      expect(document.match_id).to be_nil
    end

    it "close without documents leaves Padaria month_id nil" do
      document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

      month.close_for_send

      expect(document.reload.month_id).to be_nil
    end

    it "close with only Padaria leaves Mercado month_id nil" do
      padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
      mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "45,00")

      month.close_for_send(supporting_documents: [ padaria ])

      expect(padaria.reload.month_id).to eq(month.id)
      expect(mercado.reload.month_id).to be_nil
    end

    it "close with a document of another month does not write" do
      june = Month.open(organization: organization, year_month: "2026-06")
      document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
      document.update!(month_id: june.id)
      calls = writer.calls.size

      month.close_for_send(supporting_documents: [ document ])

      expect(month.errors[:base]).to include("Documento já pertence a um mês")
      expect(month.reload.closed?).to eq(false)
      expect(document.reload.month_id).to eq(june.id)
      expect(writer.calls.size).to eq(calls)
    end

    it "close with a matched document does not write" do
      payment = plant_payment(statement, 22000)
      document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
      Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])
      calls = writer.calls.size

      month.close_for_send(supporting_documents: [ document ])

      expect(month.errors[:base]).to include("Documento já está em um casamento")
      expect(month.reload.closed?).to eq(false)
      expect(writer.calls.size).to eq(calls)
    end

    it "close selecting Padaria when writer raises leaves month_id nil" do
      document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
      failing = Class.new do
        def replace_month_folder(**)
          raise PackageArchiveWriter::Error
        end
      end.new

      month.close_for_send(writer: failing, supporting_documents: [ document ])

      expect(month.errors[:base]).to include("Não foi possível gravar no arquivo do pacote")
      expect(month.reload.closed?).to eq(false)
      expect(document.reload.month_id).to be_nil
    end

    it "close selecting Padaria with missing document does not assign month_id" do
      plant_payment(statement, 22000)
      document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
      calls = writer.calls.size

      month.close_for_send(supporting_documents: [ document ])

      expect(month.errors[:base]).to include("Há documento faltante")
      expect(document.reload.month_id).to be_nil
      expect(writer.calls.size).to eq(calls)
    end

    it "reopen after unmatched Padaria close keeps month_id and does not write" do
      document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
      month.close_for_send(supporting_documents: [ document ])
      calls = writer.calls.size

      month.reopen

      expect(month.reload.closed?).to eq(false)
      expect(writer.calls.size).to eq(calls)
      document.reload
      expect(document.month_id).to eq(month.id)
      expect(document.match_id).to be_nil
    end

    it "re-close without documents keeps unmatched Padaria month_id" do
      document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
      month.close_for_send(supporting_documents: [ document ])
      month.reopen

      month.close_for_send

      document.reload
      expect(document.month_id).to eq(month.id)
      expect(document.match_id).to be_nil
    end

    it "restore_month_folder rewrites the same folder_id and stays closed" do
      payment = plant_payment(statement, 22000)
      mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "220,00")
      Match.confirm(month: month, payments: [ payment ], supporting_documents: [ mercado ])
      padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
      month.close_for_send(supporting_documents: [ padaria ])
      folder_id = month.reload.month_folder_id
      calls = writer.calls.size

      month.restore_month_folder

      expect(month.errors).to be_empty
      expect(month.reload.closed?).to eq(true)
      expect(month.month_folder_id).to eq(folder_id)
      expect(padaria.reload.month_id).to eq(month.id)
      expect(writer.calls.size).to eq(calls + 1)
      call = writer.calls.last
      expect(call[:folder_id]).to eq(folder_id)
      expect(call[:files].keys).to include(
        "notas-sem-casamento/recibo-2026-05-11-padaria-central-#{padaria.id}.jpg",
        "notas/recibo-2026-05-11-mercado-silva-#{mercado.id}.jpg",
        "resumo-2026-05.xlsx"
      )
    end

    it "restore_month_folder while open does not write" do
      calls = writer.calls.size

      month.restore_month_folder

      expect(month.errors[:base]).to include("Mês aberto")
      expect(writer.calls.size).to eq(calls)
    end

    it "restore_month_folder when writer raises keeps folder_id" do
      month.close_for_send
      folder_id = month.reload.month_folder_id
      failing = Class.new do
        def replace_month_folder(**)
          raise PackageArchiveWriter::Error
        end
      end.new

      month.restore_month_folder(writer: failing)

      expect(month.errors[:base]).to include("Não foi possível gravar no arquivo do pacote")
      expect(month.reload.closed?).to eq(true)
      expect(month.month_folder_id).to eq(folder_id)
    end
  end

  describe "concurrent closes persist closed once and write once" do
    self.use_transactional_tests = false

    it "concurrent closes persist closed once and write once" do
      truncate_product_tables
      org = create_organization!(
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

  describe "concurrent close of two months with the same Padaria" do
    self.use_transactional_tests = false

    it "concurrent close of two months with the same Padaria assigns one month_id" do
      truncate_product_tables
      org = create_organization!(
        name: "ONG Norte",
        accountant_presentation_name: "Maria Contadora",
        package_archive_folder_id: CloseHelpers::ARCHIVE_FOLDER_ID
      )
      coord = Account.create!(email: "coord@example.com", google_uid: "uid-coord")
      may, _may_statement = plant_month(org, year_month: "2026-05")
      june, _june_statement = plant_month(org, year_month: "2026-06")
      document = plant_recibo(org, coord, payee: "Padaria Central", amount: "155,00")
      memory_may = PackageArchiveWriter::Memory.new
      memory_june = PackageArchiveWriter::Memory.new
      queue = Queue.new
      queue << [ may.id, memory_may ]
      queue << [ june.id, memory_june ]

      run_in_parallel(2) do
        month_id, memory = queue.pop
        Month.find(month_id).close_for_send(
          writer: memory,
          supporting_documents: [ SupportingDocument.find(document.id) ]
        )
      end

      closed = Month.where(id: [ may.id, june.id ], closed: true)
      expect(closed.count).to eq(1)
      expect(SupportingDocument.find(document.id).month_id).to eq(closed.first.id)
      winner_memory, loser_memory = [ memory_may, memory_june ].partition { |memory| memory.calls.any? }
      expect(winner_memory.size).to eq(1)
      expect(loser_memory.first.calls.size).to eq(0)
    ensure
      truncate_product_tables
    end
  end

  describe "concurrent restore_month_folder" do
    self.use_transactional_tests = false

    it "concurrent restore_month_folder keeps closed and folder_id" do
      truncate_product_tables
      org = create_organization!(
        name: "ONG Norte",
        accountant_presentation_name: "Maria Contadora",
        package_archive_folder_id: CloseHelpers::ARCHIVE_FOLDER_ID
      )
      month, _statement = plant_month(org)
      memory = PackageArchiveWriter::Memory.new
      Month.find(month.id).close_for_send(writer: memory)
      folder_id = month.reload.month_folder_id

      run_in_parallel(2) do
        Month.find(month.id).restore_month_folder(writer: memory)
      end

      expect(month.reload.closed?).to eq(true)
      expect(month.month_folder_id).to eq(folder_id)
    ensure
      truncate_product_tables
    end
  end
end
