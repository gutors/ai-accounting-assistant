require "rails_helper"

RSpec.describe "Month overview", type: :request do
  it "GET month chrome is Voltar title Casar Fechar and omits stamp" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization)

    get "/months/2026-05"

    expect(response).to have_http_status(:ok)
    doc = page_doc(response.body)
    expect(doc.at_css("h1").text.strip).to eq("maio de 2026")
    meta = doc.at_css("h1").parent.at_css("p")
    expect(meta.text.strip).to eq("2026-05")
    expect(meta["class"]).to include("text-meta")
    expect(meta["class"]).to include("text-ink-soft")
    main = doc.at_css("main")
    first_link = main.css("a").first
    expect(first_link.text.strip).to eq("Voltar para Início")
    expect(first_link["href"]).to eq("/")
    expect(first_link["class"]).to include("text-caixa")
    expect(first_link["class"]).to include("underline")
    inicio = doc.at_css("header a")
    expect(inicio.text.strip).to eq("Início")
    expect(inicio["href"]).to eq("/")
    casar = doc.css("a").find { |node| node.text.strip == "Casar pagamentos" }
    expect(casar["class"]).to include("ds-btn-secondary")
    expect(casar["href"]).to eq("/months/2026-05/matches")
    cluster_html = casar.parent.to_html
    expect(cluster_html.index("Casar pagamentos")).to be < cluster_html.index("Fechar para envio")
    fechar = doc.at_css('input[type="submit"][value="Fechar para envio"]')
    expect(fechar["class"]).to include("ds-btn-primary")
    expect(fechar.ancestors("form").first["id"]).to eq("close-month")
    expect(fechar.ancestors("form").first["data-wait-copy"]).to eq("Escrevendo a pasta do mês…")
    expect(doc.at_css('[data-stamp="closed"]')).to be_nil
  end

  it "closed GET month Voltar stamp under title Restaurar Reabrir omits Casar Fechar" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, _statement = plant_month(organization)
    month.update!(closed: true)

    get "/months/2026-05"

    doc = page_doc(response.body)
    first_link = doc.at_css("main").css("a").first
    expect(first_link.text.strip).to eq("Voltar para Início")
    stamp = doc.at_css('[data-stamp="closed"]')
    expect(stamp.text.strip).to eq("Mês fechado")
    expect(stamp["class"]).to include("stamp-closed")
    title_block = stamp.parent
    expect(title_block.at_css("h1")).to be_present
    expect(title_block.text).not_to include("Restaurar pasta")
    expect(title_block.at_css("p").text.strip).to eq("2026-05")
    restore = doc.css("button").find { |node| node.text.strip == "Restaurar pasta" }
    reopen = doc.css("button").find { |node| node.text.strip == "Reabrir" }
    expect(restore["class"]).to include("ds-btn-secondary")
    expect(reopen["class"]).to include("ds-btn-secondary")
    expect(restore.ancestors("form").first["data-turbo-confirm"]).to eq("Restaurar a pasta do mês no arquivo do pacote?")
    expect(restore.ancestors("form").first["data-wait-copy"]).to eq("Restaurando a pasta do mês…")
    expect(reopen.ancestors("form").first["data-turbo-confirm"]).to eq("Reabrir o mês?")
    expect(reopen.ancestors("form").first["data-wait-copy"]).to eq("Reabrindo o mês…")
    expect(response.body).not_to include("Casar pagamentos")
    expect(response.body).not_to include("Fechar para envio")
  end

  it "unconfirmed GET month Voltar Fechar omits Casar chips and folds" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization, accounts_confirmed: false)

    get "/months/2026-05"

    expect(response.body).to include("Voltar para Início")
    expect(response.body).to include("Fechar para envio")
    expect(response.body).not_to include("Casar pagamentos")
    expect(page_doc(response.body).at_css('[role="group"][aria-label="Conta bancária"]')).to be_nil
    expect(response.body).not_to include(">Todas<")
    expect(page_doc(response.body).css("details.month-fold")).to be_empty
  end

  it "blocked open month Fechar para envio is present and not disabled" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    _month, statement = plant_month(organization)
    plant_payment(statement, 22000)
    BankAccount.create_for(organization: organization, name: "Conta Alfa", compe: "033")

    get "/months/2026-05"

    fechar = page_doc(response.body).at_css('input[type="submit"][value="Fechar para envio"]')
    expect(fechar).to be_present
    expect(fechar["disabled"]).to be_nil
    expect(response.body).to include("1 pagamento com documento faltante")
    expect(response.body).to include("Falta o extrato")
  end

  it "GET month Contas then chips then three fold summaries Recebimentos last" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization)

    get "/months/2026-05"

    doc = page_doc(response.body)
    contas = doc.css("h2").find { |node| node.text.strip == "Contas bancárias" }
    expect(contas.ancestors("details")).to be_empty
    html = doc.at_css("main").inner_html
    expect(html.index("pagamento com documento faltante") || html.index("Nenhum documento faltante")).to be < html.index("Contas bancárias")
    chips = doc.at_css('[role="group"][aria-label="Conta bancária"]')
    folds = doc.css("details.month-fold")
    expect(folds.map { |node| node.at_css("summary").text.strip }).to eq(
      [ "Pagamentos", "Documentos sem casamento", "Recebimentos" ]
    )
    expect(html.index(chips.to_html)).to be < html.index(folds[0].to_html)
    expect(html.index(folds[0].to_html)).to be < html.index(folds[1].to_html)
    expect(html.index(folds[1].to_html)).to be < html.index(folds[2].to_html)
    expect(month_h2s(response.body)).not_to include("Pagamentos")
    expect(month_h2s(response.body)).not_to include("Documentos sem casamento")
    expect(month_h2s(response.body)).not_to include("Recebimentos")
  end

  it "GET month three folds stay open with empty payments and inflows" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization)

    get "/months/2026-05"

    folds = page_doc(response.body).css("details.month-fold")
    expect(folds.size).to eq(3)
    expect(folds).to all(satisfy { |node| node.has_attribute?("open") })
    expect(rows(response.body, "payment")).to be_empty
    expect(rows(response.body, "inflow")).to be_empty
    pagamentos = month_fold(response.body, "Pagamentos")
    recebimentos = month_fold(response.body, "Recebimentos")
    expect(pagamentos.text).not_to include("Nenhum pagamento")
    expect(recebimentos.text).not_to include("Nenhum recebimento")
  end

  it "unconfirmed GET month confirm step follows Contas and omits folds" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization, accounts_confirmed: false)

    get "/months/2026-05"

    headings = month_h2s(response.body)
    expect(headings.index("Contas bancárias")).to be < headings.index("Confirmar contas para fechamento")
    expect(page_doc(response.body).at_css('input[type="submit"][value="Iniciar fechamento"]')).to be_present
    expect(page_doc(response.body).css("details.month-fold")).to be_empty
  end

  it "GET month chips Todas Alfa Principal with Todas current" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    alfa = BankAccount.create_for(organization: organization, name: "Conta Alfa", compe: "001")
    principal = BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "033")
    plant_month(organization)

    get "/months/2026-05"

    links = month_chip_links(response.body)
    expect(links.map { |node| node.text.strip }).to eq([ "Todas", "Conta Alfa", "Conta Principal" ])
    expect(links[0]["aria-current"]).to eq("true")
    expect(links[0]["href"]).to eq("/months/2026-05")
    expect(links[1]["href"]).to eq("/months/2026-05?bank_account_id=#{alfa.id}")
    names = rows(response.body, "bank-account").map { |row| row.element_children[1].text.strip }
    expect(names).to include("Conta Alfa", "Conta Principal")
    expect(principal).to be_present
  end

  it "GET month filter Principal hides Alfa movements keeps pool and Casar query" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    BankAccount.create_for(organization: organization, name: "Conta Alfa", compe: "001")
    principal = BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "033")
    BankAccount.create_for(organization: organization, name: "Conta Sem Extrato", compe: "237")
    month, alfa_statement = plant_month(organization)
    principal_statement = BankStatement.create!(month: month, bank_account: principal)
    plant_payment(principal_statement, 22000, history: "Pix enviado — Padaria Central")
    plant_inflow(principal_statement, 6300)
    plant_payment(alfa_statement, 45000, history: "TED — Energia Ltda")
    plant_inflow(alfa_statement, 10000, history: "Pix Alfa")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05", params: { bank_account_id: principal.id }

    current = month_chip_links(response.body).find { |node| node["aria-current"] == "true" }
    expect(current.text.strip).to eq("Conta Principal")
    todas = month_chip_links(response.body).find { |node| node.text.strip == "Todas" }
    expect(todas["aria-current"]).to be_nil
    pagamentos = month_fold(response.body, "Pagamentos")
    expect(pagamentos.text).to include("Pix enviado — Padaria Central")
    expect(pagamentos.text).to include("Conta Principal")
    expect(pagamentos.text).not_to include("TED — Energia Ltda")
    recebimentos = month_fold(response.body, "Recebimentos")
    expect(recebimentos.text).to include("R$ 63,00")
    expect(recebimentos.text).not_to include("Pix Alfa")
    summary = page_doc(response.body).css("span").find { |node| node.text.include?("documento faltante") }
    expect(summary.text.strip).to eq("1 pagamento com documento faltante.")
    expect(summary["class"]).to include("text-margem")
    expect(month_fold(response.body, "Documentos sem casamento").text).to include("Padaria Central")
    chips = page_doc(response.body).at_css('[role="group"][aria-label="Conta bancária"]')
    expect(chips.text).not_to include("Falta o extrato")
    expect(response.body).to include("Falta o extrato")
    casar = page_doc(response.body).css("a").find { |node| node.text.strip == "Casar pagamentos" }
    expect(casar["href"]).to eq("/months/2026-05/matches?bank_account_id=#{principal.id}")
  end

  it "POST close 422 keeps bank_account_id filter on re-render" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    BankAccount.create_for(organization: organization, name: "Conta Alfa", compe: "001")
    principal = BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "033")
    month, alfa_statement = plant_month(organization)
    principal_statement = BankStatement.create!(month: month, bank_account: principal)
    plant_payment(principal_statement, 22000, history: "Pix enviado — Padaria Central")
    plant_payment(alfa_statement, 45000, history: "TED — Energia Ltda")

    get "/months/2026-05", params: { bank_account_id: principal.id }
    post "/months/2026-05/close", params: { bank_account_id: principal.id }

    expect(response).to have_http_status(:unprocessable_content)
    current = month_chip_links(response.body).find { |node| node["aria-current"] == "true" }
    expect(current.text.strip).to eq("Conta Principal")
    pagamentos = month_fold(response.body, "Pagamentos")
    expect(pagamentos.text).to include("Pix enviado — Padaria Central")
    expect(pagamentos.text).not_to include("TED — Energia Ltda")
    doc = page_doc(response.body)
    expect(doc.at_css('input[name="bank_account_id"][value="' + principal.id.to_s + '"]')).to be_present
  end

  it "GET month unfiltered missing count is two and filtered none omits margem" do
    _account, organization = plant_coordinator
    sign_in_as(_account, organization: organization)
    BankAccount.create_for(organization: organization, name: "Conta Alfa", compe: "001")
    principal = BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "033")
    month, alfa_statement = plant_month(organization)
    principal_statement = BankStatement.create!(month: month, bank_account: principal)
    plant_payment(principal_statement, 22000, history: "Pix enviado — Padaria Central")
    plant_payment(alfa_statement, 45000, history: "TED — Energia Ltda")

    get "/months/2026-05"

    two = page_doc(response.body).css("span").find { |node| node.text.include?("documento faltante") }
    expect(two.text.strip).to eq("2 pagamentos com documento faltante.")
    expect(two["class"]).to include("text-margem")

    Payment.find_by!(history: "Pix enviado — Padaria Central").mark_document_exception("bank_fee")

    get "/months/2026-05", params: { bank_account_id: principal.id }

    none = page_doc(response.body).css("span").find { |node| node.text.include?("documento faltante") }
    expect(none.text.strip).to eq("Nenhum documento faltante.")
    expect(none["class"].to_s).not_to include("text-margem")
  end

  it "GET month unknown inactive or foreign bank_account_id is 404" do
    _account, organization = plant_coordinator
    sign_in_as(_account, organization: organization)
    plant_month(organization)
    foreign = create_organization!(name: "ONG Sul")
    other = BankAccount.create_for(organization: foreign, name: "Conta Estranha", compe: "001")
    inactive = BankAccount.create_for(organization: organization, name: "Conta Morta", compe: "237")
    inactive.update!(active: false)

    get "/months/2026-05", params: { bank_account_id: 0 }
    expect(response).to have_http_status(:not_found)

    get "/months/2026-05", params: { bank_account_id: other.id }
    expect(response).to have_http_status(:not_found)

    get "/months/2026-05", params: { bank_account_id: inactive.id }
    expect(response).to have_http_status(:not_found)
  end

  it "unconfirmed GET month with valid bank_account_id is 200 and hides movements" do
    _account, organization = plant_coordinator
    sign_in_as(_account, organization: organization)
    month, statement = plant_month(organization, accounts_confirmed: false)
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")

    get "/months/2026-05", params: { bank_account_id: statement.bank_account_id }

    expect(response).to have_http_status(:ok)
    expect(page_doc(response.body).css("details.month-fold")).to be_empty
    expect(rows(response.body, "payment")).to be_empty
    expect(month).to be_present
  end

  it "GET month Pagamentos head Data Historico Valor Status Documento no Acoes" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    _month, statement = plant_month(organization)
    earlier = plant_payment(statement, 10000, history: "Primeiro", occurred_on: Date.new(2026, 5, 10))
    later = plant_payment(statement, 12000, history: "Segundo", occurred_on: Date.new(2026, 5, 11))

    get "/months/2026-05"

    head = month_fold(response.body, "Pagamentos").at_css(".ledger-head")
    expect(head.element_children.map { |node| node.text.strip }).to eq([ "Data", "Histórico", "Valor", "Status", "Documento" ])
    expect(head.text).not_to include("Ações")
    ids = rows(response.body, "payment").map { |row| row["data-payment-id"].to_i }
    expect(ids).to eq([ earlier.id, later.id ])
  end

  it "GET month missing payment suggestion empty Documento and no Resolver" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    _month, statement = plant_month(organization)
    statement.bank_account.update!(name: "Conta Principal")
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central", occurred_on: Date.new(2026, 5, 11))
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    row = page_doc(response.body).css('li[data-row="payment"][data-status="missing"]').find { |node|
      node.text.include?("Pix enviado — Padaria Central")
    }
    expect(row["class"]).to include("is-block")
    expect(row.at_css("time")["datetime"]).to eq("2026-05-11")
    expect(row.text).to include("Pix enviado — Padaria Central")
    expect(row.text).to include("Conta Principal")
    expect(row.text).to include("R$ 220,00")
    faltante = row.at_css('[data-cell="status"] .text-margem')
    expect(faltante.text.strip).to eq("Documento faltante")
    expect(row.at_css('[data-cell="status"]').text).to include("Sugestão Padaria Central")
    expect(row.at_css('[data-cell="document"]').text.strip).to eq("")
    expect(row.text).not_to include("Resolver")
    expect(row.css("form")).to be_empty
    expect(row.to_html).not_to include("/months/2026-05/matches")
  end

  it "GET month Casado Documento payees observation not in Status no Desfazer" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "65,00")
    Match.confirm(
      month: month,
      payments: [ payment ],
      supporting_documents: [ padaria, mercado ],
      observation: "desconto não documentado"
    )
    other = plant_payment(statement, 10000, history: "Pix enviado — Outro")
    pair = plant_payment(statement, 8000, history: "Pix enviado — Par")
    n1 = plant_recibo(organization, account, payee: "Padaria Central", amount: "180,00", date: "2026-05-13")
    Match.confirm(month: month, payments: [ other, pair ], supporting_documents: [ n1 ])

    get "/months/2026-05"

    matched = row(response.body, "payment", payment_id: payment.id)
    expect(matched["data-status"]).to eq("matched")
    status = matched.at_css('[data-cell="status"]').text
    expect(status).to include("Casado")
    expect(status).to include("desconto não documentado")
    expect(status).not_to include("Padaria Central")
    expect(status).not_to include("Mercado Silva")
    expect(matched.at_css('[data-cell="document"]').text.strip).to eq("Padaria Central, Mercado Silva")
    expect(matched.text).not_to include("Desfazer casamento")
    n1_row = row(response.body, "payment", payment_id: other.id)
    expect(n1_row.at_css('[data-cell="document"]').text.strip).to eq("Padaria Central")
    expect(row(response.body, "payment", payment_id: pair.id).at_css('[data-cell="document"]').text.strip).to eq("Padaria Central")
  end

  it "GET month exception Status empty Documento no Desmarcar including closed deactivated extra" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação", justification: "Isento de documento de suporte.")
    month, statement = plant_month(organization)
    fee = plant_payment(statement, 15500, history: "Tarifa")
    fee.mark_document_exception("bank_fee")
    honor = plant_payment(statement, 80000, history: "Honorarios")
    honor.mark_document_exception("accountant_fee")
    extra = plant_payment(statement, 22000, history: "Doacao")
    extra.mark_document_exception(extra_exception_kind_id: kind.id)

    get "/months/2026-05"

    [ fee, honor, extra ].each do |payment|
      listed = row(response.body, "payment", payment_id: payment.id)
      expect(listed.at_css('[data-cell="document"]').text.strip).to eq("")
      expect(listed.text).not_to include("Desmarcar exceção")
    end
    expect(row(response.body, "payment", payment_id: fee.id).at_css('[data-cell="status"]').text).to include("Tarifa bancária")
    expect(row(response.body, "payment", payment_id: honor.id).at_css('[data-cell="status"]').text).to include("Honorário do contador")
    expect(row(response.body, "payment", payment_id: extra.id).at_css('[data-cell="status"]').text).to include("Doação")

    kind.apply_active(false)
    month.update!(closed: true)
    get "/months/2026-05"
    expect(row(response.body, "payment", payment_id: extra.id).at_css('[data-cell="status"]').text).to include("Doação")
  end

  it "GET month omits N:1 Marcar tarifa honorario and extra kind submit" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ExtraExceptionKind.create_for(organization: organization, name: "Doação", justification: "Isento de documento de suporte.")
    _month, statement = plant_month(organization)
    plant_payment(statement, 10000, history: "Um")
    plant_payment(statement, 12000, history: "Dois")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    expect(response.body).not_to include("Casar vários pagamentos com um documento")
    expect(response.body).not_to include("Marcar tarifa")
    expect(response.body).not_to include("Marcar honorário")
    expect(response.body).not_to include("name=\"extra_exception_kind_id\"")
  end

  it "GET month pool rows date payee tipo valor foto in listed order" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization)
    padaria = SupportingDocument.insert(
      organization: organization,
      account: account,
      kind: "recibo",
      amount: "220,00",
      date: "2026-05-11",
      payee: "Padaria Central",
      photo: photo_named("foto.jpg")
    )
    mercado = SupportingDocument.insert(
      organization: organization,
      account: account,
      kind: "nota_fiscal",
      amount: "180,00",
      date: "2026-05-12",
      payee: "Mercado Silva",
      xml: authorized_xml("mercado.xml", vnf: "180.00", emit: "Mercado Silva", dhemi: "2026-05-12T10:00:00-03:00")
    )

    get "/months/2026-05"

    fold = month_fold(response.body, "Documentos sem casamento")
    head = fold.at_css(".ledger-head")
    expect(head.element_children.map { |node| node.text.strip }.first(5)).to eq(
      [ "Data", "Favorecido", "Tipo", "Valor", "Foto" ]
    )
    listed = fold.css('li[data-row="pool-document"]')
    expect(listed.map { |node| node["data-document-id"].to_i }).to eq([ mercado.id, padaria.id ])
    expect(listed[0].at_css("time")["datetime"]).to eq("2026-05-12")
    expect(listed[0].text).to include("Mercado Silva")
    expect(listed[0].text).to include("Nota fiscal")
    expect(listed[0].text).to include("R$ 180,00")
    expect(listed[1].at_css("time")["datetime"]).to eq("2026-05-11")
    expect(listed[1].text).to include("Padaria Central")
    expect(listed[1].text).to include("Recibo")
    expect(listed[1].text).to include("R$ 220,00")
    expect(fold.at_css(".ledger-overview-pool")).to be_present
  end

  it "GET month open pool close checkbox and Devolver" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, _statement = plant_month(organization)
    open_doc = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    packed = plant_recibo(organization, account, payee: "Mercado Silva", amount: "50,00", date: "2026-05-18")
    packed.update!(month_id: month.id)

    get "/months/2026-05"

    open_row = row(response.body, "pool-document", document_id: open_doc.id)
    checkbox = open_row.at_css('input[type="checkbox"]')
    expect(checkbox["form"]).to eq("close-month")
    expect(open_row.at_css("label").text.strip).to eq("Padaria Central")
    packed_row = row(response.body, "pool-document", document_id: packed.id)
    expect(packed_row.at_css('input[type="checkbox"]')).to be_nil
    devolver = packed_row.css("button").find { |node| node.text.strip == "Devolver" }
    expect(devolver["class"]).to include("text-margem")
    expect(devolver["class"]).to include("underline")
    expect(devolver.ancestors("form").first["action"]).to eq(
      "/months/2026-05/supporting_documents/#{packed.id}/return"
    )
  end

  it "GET month pool Foto filename blob link or empty" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization)
    padaria = SupportingDocument.insert(
      organization: organization,
      account: account,
      kind: "recibo",
      amount: "220,00",
      date: "2026-05-11",
      payee: "Padaria Central",
      photo: photo_named("foto.jpg")
    )
    mercado = SupportingDocument.insert(
      organization: organization,
      account: account,
      kind: "nota_fiscal",
      amount: "180,00",
      date: "2026-05-12",
      payee: "Mercado Silva",
      xml: authorized_xml("mercado.xml", vnf: "180.00", emit: "Mercado Silva", dhemi: "2026-05-12T10:00:00-03:00")
    )

    get "/months/2026-05"

    photo = row(response.body, "pool-document", document_id: padaria.id).at_css('[data-cell="photo"] a')
    expect(photo.text.strip).to eq("foto.jpg")
    expect(photo["class"]).to include("text-caixa")
    expect(photo["class"]).to include("underline")
    expect(photo["href"]).to include("/rails/active_storage/")
    expect(photo["target"]).to be_nil
    nota_photo = row(response.body, "pool-document", document_id: mercado.id).at_css('[data-cell="photo"]')
    expect(nota_photo.at_css("a")).to be_nil
    expect(nota_photo.text).not_to include(".jpg")
    expect(nota_photo.text).not_to include(".xml")
  end

  it "GET month empty pool copy and closed pool omits checkbox Devolver" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, _statement = plant_month(organization)

    get "/months/2026-05"

    pool = month_fold(response.body, "Documentos sem casamento")
    expect(pool.text).to include("Nenhum documento sem casamento")
    expect(pool.css('li[data-row="pool-document"]')).to be_empty

    packed = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    packed.update!(month_id: month.id)
    month.update!(closed: true)
    get "/months/2026-05"
    closed_pool = month_fold(response.body, "Documentos sem casamento")
    expect(closed_pool.at_css('input[type="checkbox"]')).to be_nil
    expect(closed_pool.text).not_to include("Devolver")
  end

  it "GET month Recebimentos last fold three columns omits Documento faltante" do
    _account, organization = plant_coordinator
    sign_in_as(_account, organization: organization)
    _month, statement = plant_month(organization)
    plant_inflow(statement, 6300)
    plant_payment(statement, 22000)

    get "/months/2026-05"

    expect(month_fold_summaries(response.body).last).to eq("Recebimentos")
    head = month_fold(response.body, "Recebimentos").at_css(".ledger-head")
    expect(head.element_children.map { |node| node.text.strip }).to eq([ "Data", "Histórico", "Valor" ])
    inflow = rows(response.body, "inflow").first
    expect(inflow.text).to include("Pix - Recebido")
    expect(inflow.text).to include(statement.bank_account.name)
    expect(inflow.text).to include("R$ 63,00")
    expect(month_fold(response.body, "Recebimentos").text).not_to include("Documento faltante")
  end

  it "closed GET month folds open no statement forms omits Casar matches still 200" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, _statement = plant_month(organization)
    month.update!(closed: true)

    get "/months/2026-05"

    folds = page_doc(response.body).css("details.month-fold")
    expect(folds).to all(satisfy { |node| node.has_attribute?("open") })
    expect(response.body).not_to include("Incluir extrato")
    expect(response.body).not_to include("Substituir extrato")
    expect(response.body).not_to include("Casar pagamentos")

    get "/months/2026-05/matches"
    expect(response).to have_http_status(:ok)
  end

  it "422 close re-renders month without Resolver" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    _month, statement = plant_month(organization)
    plant_payment(statement, 22000)

    post "/months/2026-05/close"

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).not_to include("Resolver")
    expect(page_doc(response.body).at_css("h1").text.strip).to eq("maio de 2026")
  end
end
