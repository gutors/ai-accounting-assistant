require "rails_helper"

RSpec.describe "Close for send", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  def signed_ready
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ready_to_close!(organization)
    month, statement = plant_month(organization)
    [ account, organization, month, statement ]
  end

  def post_close(year_month = "2026-05", **params)
    if params.empty?
      post "/months/#{year_month}/close"
    else
      post "/months/#{year_month}/close", params: params
    end
  end

  def padaria_unmatched_path(document)
    "notas-sem-casamento/recibo-2026-05-11-padaria-central-#{document.id}.jpg"
  end

  it "POST close while exception suggestion showing returns 422 Ha documento faltante" do
    _account, organization, month, statement = signed_ready
    organization.update!(accountant_pix_key: "chave-pix")
    plant_payment(statement, 22000, history: "Pix enviado chave-pix")

    get "/months/2026-05"
    expect(payment_status_html(response.body, history: "Pix enviado chave-pix")).to include("Sugestão de exceção")

    post_close

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Há documento faltante")
    expect(month.reload.closed?).to eq(false)
  end

  it "closed month shows the stamp and no details" do
    _account, _organization, _month, statement = signed_ready
    attach_statement_files(statement)
    plant_payment(statement, 15500, history: "Tarifa").mark_document_exception("bank_fee")
    post_close

    get "/months/2026-05"

    expect(response).to have_http_status(:ok)
    stamp = page_doc(response.body).at_css('[data-stamp="closed"]')
    expect(stamp).not_to be_nil
    expect(stamp.text.strip).to eq("Mês fechado")
    expect(response.body).not_to include("Incluir extrato")
    expect(response.body).not_to include("Substituir extrato")
    expect(page_doc(response.body).css("details.month-fold")).not_to be_empty
  end

  it "month error renders as a data-notice error alert" do
    _account, _organization, _month, statement = signed_ready
    plant_payment(statement, 22000)

    post_close

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Há documento faltante")
  end

  it "POST close with missing document 22000 cents returns 422 Ha documento faltante" do
    _account, organization, month, statement = signed_ready
    plant_payment(statement, 22000)
    calls = writer.calls.size

    post_close

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Há documento faltante")
    expect(month.reload.closed?).to eq(false)
    expect(writer.calls.size).to eq(calls)
  end

  it "POST close with active account Falta returns 422 Importe o extrato" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ready_to_close!(organization)
    BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    post "/months", params: { year_month: "2026-05" }
    month = organization.months.find_by!(year_month: "2026-05")

    post_close

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Importe o extrato de cada conta ativa")
    expect(month.reload.closed?).to eq(false)
  end

  it "POST close without archive folder id returns 422 Informe a pasta" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    organization.update!(accountant_presentation_name: "Maria Contadora")
    plant_month(organization)

    post_close

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Informe a pasta do arquivo do pacote")
    expect(organization.months.find_by!(year_month: "2026-05").closed?).to eq(false)
  end

  it "POST close without accountant name returns 422 Cadastre o contador" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    organization.update!(package_archive_folder_id: CloseHelpers::ARCHIVE_FOLDER_ID)
    plant_month(organization)

    post_close

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Cadastre o contador")
    expect(organization.months.find_by!(year_month: "2026-05").closed?).to eq(false)
  end

  it "POST close ready month persists closed 302 and writes once" do
    _account, organization, month, _statement = signed_ready

    post_close

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    expect(month.reload.closed?).to eq(true)
    expect(writer.calls.size).to eq(1)
    expect(writer.calls.first[:parent_id]).to eq(CloseHelpers::ARCHIVE_FOLDER_ID)
  end

  it "GET closed 2026-05 includes Mes fechado and omits Fechar para envio" do
    _account, _organization, _month, _statement = signed_ready
    post_close

    get "/months/2026-05"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Mês fechado")
    expect(response.body).not_to include("Fechar para envio")
  end

  it "unauthenticated POST close responds 302 to /login" do
    _account, organization = plant_coordinator
    ready_to_close!(organization)
    month, _statement = plant_month(organization)

    post_close

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
    expect(month.reload.closed?).to eq(false)
  end

  it "POST close when writer raises returns 422 Nao foi possivel gravar" do
    _account, organization, month, _statement = signed_ready
    allow(PackageArchiveWriter.current).to receive(:replace_month_folder).and_raise(PackageArchiveWriter::Error)

    post_close

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Não foi possível gravar no arquivo do pacote")
    expect(month.reload.closed?).to eq(false)
  end

  it "POST close while already closed returns 422 Mes fechado" do
    _account, _organization, month, _statement = signed_ready
    post_close
    calls = writer.calls.size

    post_close

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Mês fechado")
    expect(month.reload.closed?).to eq(true)
    expect(writer.calls.size).to eq(calls)
  end

  it "POST close with inactive account without statement succeeds 302" do
    _account, organization, month, _statement = signed_ready
    inactive = BankAccount.create_for(organization: organization, name: "Conta Antiga", compe: "001")
    inactive.apply_from(active: false)

    post_close

    expect(response).to have_http_status(:found)
    expect(month.reload.closed?).to eq(true)
  end

  it "closed package xlsx sheet is 2026-05 titled Planilha-resumo ONG Norte" do
    _account, _organization, _month, _statement = signed_ready
    post_close
    book = parse_resumo

    expect(book.worksheets.size).to eq(1)
    expect(book[0].sheet_name).to eq("2026-05")
    expect(sheet_text(book)).to include("Planilha-resumo — ONG Norte")
  end

  it "xlsx includes Maria Contadora Contabil LTDA and formatted CNPJ" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    organization.update_accountant(
      presentation_name: "Maria Contadora",
      tax_id: "11222333000181",
      legal_name: "Contábil LTDA"
    )
    organization.update!(package_archive_folder_id: CloseHelpers::ARCHIVE_FOLDER_ID)
    plant_month(organization)

    post_close
    text = sheet_text(parse_resumo)

    expect(text).to include("Maria Contadora")
    expect(text).to include("Contábil LTDA")
    expect(text).to include("11.222.333/0001-81")
  end

  it "xlsx CPF omits razao social and includes formatted CPF" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    organization.update_accountant(presentation_name: "Maria Contadora", tax_id: "39053344705")
    organization.update!(package_archive_folder_id: CloseHelpers::ARCHIVE_FOLDER_ID)
    plant_month(organization)

    post_close
    text = sheet_text(parse_resumo)

    expect(text).to include("390.533.447-05")
    expect(text).not_to include("Contábil LTDA")
  end

  it "xlsx omits chave-pix and destination email" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    organization.update_accountant(
      presentation_name: "Maria Contadora",
      pix_key: "chave-pix",
      destination_email: "ana@example.com"
    )
    organization.update!(package_archive_folder_id: CloseHelpers::ARCHIVE_FOLDER_ID)
    plant_month(organization)

    post_close
    text = sheet_text(parse_resumo)

    expect(text).not_to include("chave-pix")
    expect(text).not_to include("ana@example.com")
  end

  it "xlsx Recebimentos includes 04/05/2026 numeric 63 Conta Principal Pix - Recebido" do
    _account, _organization, _month, statement = signed_ready
    plant_inflow(statement, 6300, history: "Pix - Recebido")

    post_close
    values = sheet_cell_values(parse_resumo)
    row = values.find { |cells| cells.include?("04/05/2026") && cells.include?(63) }

    expect(row).to include("Conta Principal", "Pix - Recebido")
  end

  it "xlsx bank_fee row includes Tarifa bancaria numeric 155 empty files" do
    _account, _organization, _month, statement = signed_ready
    payment = plant_payment(statement, 15500, history: "Tarifa Pacote de Serviços")
    payment.mark_document_exception("bank_fee")

    post_close
    values = sheet_cell_values(parse_resumo)
    header = custos_header_row(values)
    arquivos_index = header.index("Arquivo(s)")
    row = custos_data_rows(values).find { |cells| cells.include?("Tarifa bancária") }

    expect(row).to include(155, "Tarifa Pacote de Serviços")
    expect(row[arquivos_index]).to eq("")
  end

  it "xlsx 1N Arquivos joins notas filenames with semicolon space" do
    account, organization, month, statement = signed_ready
    payment = plant_payment(statement, 22000)
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "100,00", date: "2026-05-11")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "120,00", date: "2026-05-12")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ padaria, mercado ])

    post_close
    names = [ padaria, mercado ].flat_map { |document| MonthPackage.document_package_names(document.reload) }
    joined = names.join("; ")
    row = custos_data_rows(sheet_cell_values(parse_resumo)).find { |cells| cells.include?(220) }

    expect(row).to include(joined)
    expect(joined).to include("; ")
  end

  it "xlsx N1 both expense rows include the same notas filename" do
    account, organization, month, statement = signed_ready
    pay_a = plant_payment(statement, 10000, occurred_on: Date.new(2026, 5, 4))
    pay_b = plant_payment(statement, 12000, occurred_on: Date.new(2026, 5, 20))
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    Match.confirm(month: month, payments: [ pay_a, pay_b ], supporting_documents: [ document ])
    filename = MonthPackage.document_package_names(document.reload).first

    post_close
    rows = custos_data_rows(sheet_cell_values(parse_resumo)).select { |cells| cells.intersect?([ 100, 120 ]) }

    expect(rows.size).to eq(2)
    expect(rows).to all(include(filename))
  end

  it "xlsx includes desconto nao documentado" do
    account, organization, month, statement = signed_ready
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "200,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ], observation: "desconto não documentado")

    post_close

    expect(sheet_text(parse_resumo)).to include("desconto não documentado")
  end

  it "xlsx totals are SUM formulas and Resultado uses minus" do
    _account, _organization, _month, _statement = signed_ready
    post_close
    book = parse_resumo
    text = sheet_text(book)

    expect(text).to include("Receita total", "Despesas total", "Resultado mês")
    expect(formula_beside_label(book, "Receita total")).to include("SUM")
    expect(formula_beside_label(book, "Despesas total")).to include("SUM")
    expect(formula_beside_label(book, "Resultado mês")).to include("-")
  end

  it "xlsx includes Recebimentos section title" do
    _account, _organization, _month, _statement = signed_ready
    post_close

    expect(sheet_cell_values(parse_resumo).flatten).to include("Recebimentos")
  end

  it "xlsx includes Custos/Despesas section title" do
    _account, _organization, _month, _statement = signed_ready
    post_close

    expect(sheet_cell_values(parse_resumo).flatten).to include("Custos/Despesas")
  end

  it "xlsx includes Detalhe column header" do
    _account, _organization, _month, _statement = signed_ready
    post_close

    expect(sheet_cell_values(parse_resumo).flatten).to include("Detalhe")
  end

  it "xlsx includes Detalhes column header" do
    _account, _organization, _month, _statement = signed_ready
    post_close

    expect(sheet_cell_values(parse_resumo).flatten).to include("Detalhes")
  end

  it "xlsx omits sem casamento" do
    _account, _organization, _month, _statement = signed_ready
    post_close

    expect(sheet_text(parse_resumo)).not_to include("sem casamento")
  end

  it "xlsx Custos rows are 04/05/2026 then 20/05/2026" do
    _account, _organization, _month, statement = signed_ready
    first = plant_payment(statement, 10000, occurred_on: Date.new(2026, 5, 4))
    second = plant_payment(statement, 12000, occurred_on: Date.new(2026, 5, 20))
    first.mark_document_exception("bank_fee")
    second.mark_document_exception("bank_fee")

    post_close
    dates = custos_data_rows(sheet_cell_values(parse_resumo)).map(&:first)

    expect(dates).to eq([ "04/05/2026", "20/05/2026" ])
  end

  it "xlsx accountant_fee row includes Honorario do contador" do
    _account, _organization, _month, statement = signed_ready
    payment = plant_payment(statement, 15500)
    payment.mark_document_exception("accountant_fee")

    post_close

    expect(sheet_text(parse_resumo)).to include("Honorário do contador")
  end

  it "writer receives 2026-05 under archive parent with resumo-2026-05.xlsx" do
    _account, _organization, _month, _statement = signed_ready
    post_close
    call = writer.calls.last

    expect(call[:name]).to eq("2026-05")
    expect(call[:parent_id]).to eq(CloseHelpers::ARCHIVE_FOLDER_ID)
    expect(call[:files].keys).to include("resumo-2026-05.xlsx")
  end

  it "writer files include extrato-conta-principal pdf and xlsx" do
    _account, _organization, _month, statement = signed_ready
    attach_statement_files(statement, spreadsheet: "extrato.xlsx")

    post_close

    expect(writer_files.keys).to include("extratos/extrato-conta-principal.pdf", "extratos/extrato-conta-principal.xlsx")
  end

  it "writer files include extrato-conta-principal.csv not xlsx" do
    _account, _organization, _month, statement = signed_ready
    attach_statement_files(statement, spreadsheet: "extrato.csv")

    post_close

    expect(writer_files.keys).to include("extratos/extrato-conta-principal.csv")
    expect(writer_files.keys).not_to include("extratos/extrato-conta-principal.xlsx")
  end

  it "writer files include notas recibo padaria-central jpg with document id" do
    account, organization, month, statement = signed_ready
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])

    post_close
    path = "notas/recibo-2026-05-11-padaria-central-#{document.id}.jpg"

    expect(writer_files.keys).to include(path)
  end

  it "writer files include nota mercado-silva jpg and xml same stem" do
    account, organization, month, statement = signed_ready
    payment = plant_payment(statement, 22000)
    document = plant_nota(organization, account, payee: "Mercado Silva", amount: "220,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])

    post_close
    stem = "notas/nota-2026-05-11-mercado-silva-#{document.id}"

    expect(writer_files.keys).to include("#{stem}.jpg", "#{stem}.xml")
  end

  it "writer files omit notas-sem-casamento" do
    _account, _organization, _month, _statement = signed_ready
    post_close

    expect(writer_files.keys.grep(/\Anotas-sem-casamento\//)).to eq([])
  end

  it "first close persists month_folder_id from writer" do
    _account, _organization, month, _statement = signed_ready
    post_close

    expect(month.reload.month_folder_id).to eq(writer.folders.keys.first)
    expect(month.month_folder_id).to be_present
  end

  it "second close replaces the same folder id" do
    _account, _organization, month, _statement = signed_ready
    post_close
    folder_id = month.reload.month_folder_id
    post "/months/2026-05/reopen"
    post_close

    expect(month.reload.month_folder_id).to eq(folder_id)
    expect(writer.folders.count { |_id, folder| folder[:name] == "2026-05" && folder[:parent_id] == CloseHelpers::ARCHIVE_FOLDER_ID }).to eq(1)
    expect(writer.calls.last[:folder_id]).to eq(folder_id)
  end

  it "POST close with two 2026-05 folders returns 422 Nao foi possivel gravar" do
    _account, _organization, month, _statement = signed_ready
    writer.plant(id: "dup-a", parent_id: CloseHelpers::ARCHIVE_FOLDER_ID, name: "2026-05")
    writer.plant(id: "dup-b", parent_id: CloseHelpers::ARCHIVE_FOLDER_ID, name: "2026-05")

    post_close

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Não foi possível gravar no arquivo do pacote")
    expect(month.reload.closed?).to eq(false)
  end

  it "GET closed month is view-only with Reabrir" do
    account, organization, month, statement = signed_ready
    payment = plant_payment(statement, 22000, history: "Pix enviado")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])
    post_close

    get "/months/2026-05"

    expect(response.body).to include("Mês fechado")
    expect(response.body).to include("Reabrir")
    expect(response.body).not_to include("Enviar extrato")
    expect(response.body).not_to include("Confirmar casamento")
    expect(response.body).not_to include("Marcar tarifa")
    expect(response.body).not_to include("Desfazer casamento")
  end

  it "GET closed month still includes Casado and payment history" do
    account, organization, month, statement = signed_ready
    payment = plant_payment(statement, 22000, history: "Pix enviado")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])
    post_close

    get "/months/2026-05"

    expect(response.body).to include("Casado")
    expect(response.body).to include("Pix enviado")
  end

  it "POST close of another organization month returns 404" do
    account, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    ready_to_close!(org_b)
    month_b, _statement = plant_month(org_b)
    sign_in_as(account, organization: org_a)

    post_close

    expect(response).to have_http_status(:not_found)
    expect(month_b.reload.closed?).to eq(false)
  end

  it "closed month page omits another organization accountant name" do
    account, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    org_b = create_organization!(name: "B", accountant_presentation_name: "Contador Beta")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    ready_to_close!(org_a)
    plant_month(org_a)
    sign_in_as(account, organization: org_a)
    post_close

    get "/months/2026-05"

    expect(response.body).not_to include("Contador Beta")
  end

  it "POST close enqueues no job and persists closed" do
    _account, _organization, month, _statement = signed_ready
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear

    post_close

    expect(ActiveJob::Base.queue_adapter.enqueued_jobs).to eq([])
    expect(month.reload.closed?).to eq(true)
  end

  it "POST close of never-opened 2026-04 returns 404" do
    _account, _organization, _month, _statement = signed_ready

    post "/months/2026-04/close"

    expect(response).to have_http_status(:not_found)
  end

  it "submitter POST close leaves month open and responds 404" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    month, _statement = plant_month(organization)
    sign_in_as(submitter, organization: organization)

    post "/months/2026-05/close"

    expect(month.reload.closed?).to eq(false)
    expect(response).to have_http_status(:not_found)
  end

  it "POST close with no certificate and no missing document redirects" do
    _account, organization, month, _statement = signed_ready

    post_close

    expect(response).to have_http_status(:found)
    expect(month.reload.closed?).to eq(true)
    expect(organization.sefaz_titular_cnpj).to be_nil
  end

  it "POST close with expired certificate and no missing document redirects" do
    _account, organization, month, _statement = signed_ready
    travel_to Date.new(2026, 5, 11) do
      organization.install_sefaz_certificate(
        file: sefaz_pfx(not_after: Date.new(2026, 5, 11), name: "exp.pfx"),
        passphrase: "passphrase-secreta"
      )
    end

    travel_to Date.new(2026, 5, 12) do
      post_close
      expect(response).to have_http_status(:found)
      expect(month.reload.closed?).to eq(true)
    end
  end

  it "POST close with blank wrap key and no certificate redirects" do
    _account, organization, month, _statement = signed_ready

    with_env("SEFAZ_WRAP_KEY" => nil) do
      post_close
    end

    expect(response).to have_http_status(:found)
    expect(month.reload.closed?).to eq(true)
  end

  it "POST close with Padaria id assigns unmatched-in-package and writes notas-sem-casamento" do
    account, organization, month, _statement = signed_ready
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    post_close("2026-05", supporting_document_ids: [ document.id ])

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    expect(month.reload.closed?).to eq(true)
    document.reload
    expect(document.month_id).to eq(month.id)
    expect(document.match_id).to be_nil
    expect(writer_files.keys).to include(padaria_unmatched_path(document))
    expect(writer_files.keys.grep(%r{\Anotas/.*#{document.id}})).to eq([])
  end

  it "POST close omitting supporting_document_ids leaves Padaria with no month" do
    account, organization, _month, _statement = signed_ready
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    post_close

    expect(response).to have_http_status(:found)
    expect(document.reload.month_id).to be_nil
    expect(writer_files.keys.grep(/\Anotas-sem-casamento\//)).to eq([])
  end

  it "POST close with empty supporting_document_ids leaves Padaria with no month" do
    account, organization, _month, _statement = signed_ready
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    post_close("2026-05", supporting_document_ids: [])

    expect(response).to have_http_status(:found)
    expect(document.reload.month_id).to be_nil
    expect(writer_files.keys.grep(/\Anotas-sem-casamento\//)).to eq([])
  end

  it "POST close with only Padaria id leaves Mercado with no month" do
    account, organization, month, _statement = signed_ready
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "45,00")

    post_close("2026-05", supporting_document_ids: [ padaria.id ])

    expect(padaria.reload.month_id).to eq(month.id)
    expect(mercado.reload.month_id).to be_nil
    expect(writer_files.keys).to include(padaria_unmatched_path(padaria))
    expect(writer_files.keys.grep(/#{mercado.id}/)).to eq([])
  end

  it "POST close with another organization document id returns 404" do
    account, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    sign_in_as(account, organization: org_a)
    ready_to_close!(org_a)
    month_a, _statement = plant_month(org_a)
    org_b = create_organization!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    padaria = plant_recibo(org_b, account, payee: "Padaria Central", amount: "155,00")
    calls = writer.calls.size

    post_close("2026-05", supporting_document_ids: [ padaria.id ])

    expect(response).to have_http_status(:not_found)
    expect(month_a.reload.closed?).to eq(false)
    expect(padaria.reload.month_id).to be_nil
    expect(writer.calls.size).to eq(calls)
  end

  it "POST close with June unmatched-in-package returns 422 Documento ja pertence a um mes" do
    account, organization, month_may, _statement = signed_ready
    month_june, _june_statement = plant_month(organization, year_month: "2026-06")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    document.update!(month_id: month_june.id)
    calls = writer.calls.size

    post_close("2026-05", supporting_document_ids: [ document.id ])

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Documento já pertence a um mês")
    expect(month_may.reload.closed?).to eq(false)
    expect(document.reload.month_id).to eq(month_june.id)
    expect(writer.calls.size).to eq(calls)
  end

  it "POST close with a matched document returns 422 Documento ja esta em um casamento" do
    account, organization, month, statement = signed_ready
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])
    calls = writer.calls.size

    post_close("2026-05", supporting_document_ids: [ document.id ])

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Documento já está em um casamento")
    expect(month.reload.closed?).to eq(false)
    expect(writer.calls.size).to eq(calls)
  end

  it "POST close selecting Padaria when writer raises leaves month_id nil" do
    account, organization, month, _statement = signed_ready
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    allow(PackageArchiveWriter.current).to receive(:replace_month_folder).and_raise(PackageArchiveWriter::Error)

    post_close("2026-05", supporting_document_ids: [ document.id ])

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Não foi possível gravar no arquivo do pacote")
    expect(month.reload.closed?).to eq(false)
    expect(document.reload.month_id).to be_nil
  end

  it "POST close selecting Padaria with missing document 22000 returns 422" do
    account, organization, _month, statement = signed_ready
    plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    calls = writer.calls.size

    post_close("2026-05", supporting_document_ids: [ document.id ])

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Há documento faltante")
    expect(document.reload.month_id).to be_nil
    expect(writer.calls.size).to eq(calls)
  end

  it "unauthenticated POST close with supporting_document_ids responds 302 to /login" do
    account, organization = plant_coordinator
    ready_to_close!(organization)
    plant_month(organization)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    post_close("2026-05", supporting_document_ids: [ document.id ])

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
    expect(document.reload.month_id).to be_nil
  end

  it "submitter POST close with supporting_document_ids returns 404" do
    coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    ready_to_close!(organization)
    month, _statement = plant_month(organization)
    document = plant_recibo(organization, coord, payee: "Padaria Central", amount: "155,00")
    sign_in_as(submitter, organization: organization)

    post_close("2026-05", supporting_document_ids: [ document.id ])

    expect(response).to have_http_status(:not_found)
    expect(month.reload.closed?).to eq(false)
    expect(document.reload.month_id).to be_nil
  end

  it "re-close without ids keeps unmatched Padaria in notas-sem-casamento" do
    account, organization, month, _statement = signed_ready
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    post_close("2026-05", supporting_document_ids: [ document.id ])
    post "/months/2026-05/reopen"

    post_close

    expect(document.reload.month_id).to eq(month.id)
    expect(document.match_id).to be_nil
    expect(writer_files.keys).to include(padaria_unmatched_path(document))
  end

  it "close after return omits Padaria from writer files" do
    account, organization, _month, _statement = signed_ready
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    post_close("2026-05", supporting_document_ids: [ document.id ])
    post "/months/2026-05/reopen"
    post "/months/2026-05/supporting_documents/#{document.id}/return"

    post_close

    expect(document.reload.month_id).to be_nil
    expect(writer_files.keys.grep(/#{document.id}/)).to eq([])
  end

  it "xlsx unmatched section lists Padaria recibo after Resultado mes" do
    account, organization, _month, _statement = signed_ready
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    document.apply(observation: "pago em dinheiro")
    post_close("2026-05", supporting_document_ids: [ document.id ])
    values = sheet_cell_values(parse_resumo)
    resultado = values.index { |row| row.include?("Resultado mês") }
    heading = values.index { |row| row.include?("Documentos sem casamento") }
    header = unmatched_header_row(values)
    row = unmatched_data_rows(values).find { |cells| cells.include?("Padaria Central") }

    expect(parse_resumo[0].sheet_name).to eq("2026-05")
    expect(heading).to be > resultado
    expect(header).to eq([ "Arquivo", "Tipo", "Valor", "Data", "Favorecido", "Observação" ])
    expect(row).to include(
      padaria_unmatched_path(document),
      "Recibo",
      155,
      "11/05/2026",
      "Padaria Central",
      "pago em dinheiro"
    )
  end

  it "xlsx unmatched nota fiscal Arquivo joins jpg and xml" do
    account, organization, _month, _statement = signed_ready
    document = plant_nota(organization, account, payee: "Padaria Central", amount: "155,00")
    post_close("2026-05", supporting_document_ids: [ document.id ])
    row = unmatched_data_rows(sheet_cell_values(parse_resumo)).find { |cells| cells.include?("Padaria Central") }
    joined = "notas-sem-casamento/nota-2026-05-11-padaria-central-#{document.id}.jpg; notas-sem-casamento/nota-2026-05-11-padaria-central-#{document.id}.xml"

    expect(row[0]).to eq(joined)
    expect(row).to include("Nota fiscal")
  end

  it "xlsx without unmatched documents omits sem casamento" do
    _account, _organization, _month, _statement = signed_ready
    post_close

    expect(sheet_text(parse_resumo)).not_to include("sem casamento")
  end

  it "writer files keep matched Mercado under notas and omit it from unmatched" do
    account, organization, month, statement = signed_ready
    payment = plant_payment(statement, 22000)
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "220,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ mercado ])
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    post_close("2026-05", supporting_document_ids: [ padaria.id ])
    values = sheet_cell_values(parse_resumo)
    unmatched_text = unmatched_data_rows(values).flatten.compact.map(&:to_s).join("\n")

    expect(writer_files.keys).to include("notas/recibo-2026-05-11-mercado-silva-#{mercado.id}.jpg")
    expect(unmatched_text).not_to include("Mercado Silva")
  end

  describe "concurrent close of May and June with the same Padaria" do
    self.use_transactional_tests = false

    it "concurrent close of May and June with the same Padaria closes exactly one" do
      truncate_product_tables
      account, organization = plant_coordinator
      ready_to_close!(organization)
      plant_month(organization, year_month: "2026-05")
      plant_month(organization, year_month: "2026-06")
      document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
      session_may = signed_in_session(account)
      session_june = signed_in_session(account)
      headers = { "User-Agent" => ChromeUserAgent::CHROME }
      statuses = []
      mutex = Mutex.new

      threads = [
        Thread.new do
          session_may.post(
            "/months/2026-05/close",
            params: { supporting_document_ids: [ document.id ] },
            headers: headers
          )
          mutex.synchronize { statuses << session_may.response.status }
        end,
        Thread.new do
          session_june.post(
            "/months/2026-06/close",
            params: { supporting_document_ids: [ document.id ] },
            headers: headers
          )
          mutex.synchronize { statuses << session_june.response.status }
        end
      ]
      threads.each(&:join)

      closed = Month.where(organization: organization, closed: true)
      expect(closed.count).to eq(1)
      expect(document.reload.month_id).to eq(closed.first.id)
      expect(statuses).to contain_exactly(302, 422)
      expect(writer.calls.size).to eq(1)
      loser = [ session_may, session_june ].find { |host| host.response.status == 422 }
      expect(loser.response.body).to include("Documento já pertence a um mês")
    ensure
      truncate_product_tables
    end
  end
end
