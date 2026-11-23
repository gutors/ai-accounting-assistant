require "rails_helper"

RSpec.describe "Month matches screen", type: :request do
  def signed_month
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, statement = plant_month(organization)
    [ account, organization, month, statement ]
  end

  def two_account_month
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    alfa = BankAccount.create_for(organization: organization, name: "Conta Alfa", compe: "001")
    principal = BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "033")
    month, alfa_statement = plant_month(organization)
    principal_statement = BankStatement.create!(month: month, bank_account: principal)
    [ account, organization, month, alfa, principal, alfa_statement, principal_statement ]
  end

  def matches_h2s(body)
    page_doc(body).css("h2").map { |node| node.text.strip }
  end

  def chip_group(body)
    page_doc(body).at_css('[role="group"]')
  end

  def chip_links(body)
    chip_group(body).css("a")
  end

  def pagamentos_section(body)
    page_doc(body).css("section").find { |section| section.at_css("h2")&.text&.strip == "Pagamentos" }
  end

  def pool_section(body)
    page_doc(body).css("section").find { |section| section.at_css("h2")&.text&.strip == "Documentos sem casamento" }
  end

  def confirm_form(body)
    page_doc(body).at_css("#match-confirm")
  end

  def next_band(body)
    page_doc(body).css("h2").find { |node| node.text.strip == "Próxima sugestão" }&.ancestors&.find { |node|
      node["class"].to_s.split.include?("match-top")
    }
  end

  def next_hit(body)
    page_doc(body).at_css(".match-next__hit")
  end

  it "GET matches identifies page and month and omits close controls" do
    signed_month
    get "/months/2026-05/matches"
    expect(response).to have_http_status(:ok)
    doc = page_doc(response.body)
    expect(doc.at_css("h1").text.strip).to eq("Casar pagamentos")
    expect(doc.text).to include("maio de 2026", "2026-05", "Voltar ao mês")
    expect(response.body).not_to include("Fechar para envio", "Recebimentos")
    expect(doc.at_css('[data-stamp="closed"]')).to be_nil
  end

  it "GET matches workspace has payment and document sections and no close controls" do
    _account, _organization, _month, statement = signed_month
    plant_payment(statement, 10000)
    get "/months/2026-05/matches"
    doc = page_doc(response.body)
    headings = doc.at_css(".match-workspace").css("h2").map { |node| node.text.strip }
    expect(headings).to eq([ "Pagamento em análise", "Documentos selecionados" ])
    expect(doc.at_css("form#close-month")).to be_nil
    expect(doc.text).not_to include("Devolver")
  end

  it "GET matches chips Todas Alfa Principal with Todas current" do
    _account, _organization, _month, alfa, _principal, _alfa_statement, _principal_statement = two_account_month

    get "/months/2026-05/matches"

    links = chip_links(response.body)
    expect(links.map { |node| node.text.strip }).to eq([ "Todas", "Conta Alfa", "Conta Principal" ])
    expect(links[0]["aria-current"]).to eq("true")
    expect(links[0]["href"]).to eq("/months/2026-05/matches")
    expect(links[1]["href"]).to eq("/months/2026-05/matches?bank_account_id=#{alfa.id}")
    expect(links[1]["aria-current"]).to be_nil
  end

  it "GET matches filter selects Principal payment and retains eligible document" do
    account, organization, _month, _alfa, principal, alfa_statement, principal_statement = two_account_month
    plant_payment(principal_statement, 22000, history: "Pix enviado — Padaria Central")
    plant_payment(alfa_statement, 45000, history: "TED — Energia Ltda")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    get "/months/2026-05/matches", params: { bank_account_id: principal.id }
    expect(chip_links(response.body).find { |node| node["aria-current"] == "true" }.text.strip).to eq("Conta Principal")
    expect(page_doc(response.body).at_css('[data-current="true"]').text).to include("Pix enviado — Padaria Central", "Conta Principal")
    expect(response.body).not_to include("TED — Energia Ltda")
    expect(response.body).to include("1 pagamento com documento faltante.", "Padaria Central")
  end

  it "GET matches missing count follows account filter" do
    _account, _organization, _month, _alfa, principal, alfa_statement, principal_statement = two_account_month
    plant_payment(principal_statement, 22000, history: "Principal")
    plant_payment(alfa_statement, 45000, history: "Alfa")
    get "/months/2026-05/matches"
    expect(response.body).to include("2 pagamentos com documento faltante.")
    Payment.find_by!(history: "Principal").mark_document_exception("bank_fee")
    get "/months/2026-05/matches", params: { bank_account_id: principal.id }
    none = page_doc(response.body).css("p").find { |node| node.text.include?("documento faltante") }
    expect(none.text.strip).to eq("Nenhum pagamento com documento faltante.")
    expect(none["class"].to_s).not_to include("text-margem")
  end

  it "GET matches unknown or inactive bank_account_id is 404" do
    _account, organization, _month, _statement = signed_month
    foreign = create_organization!(name: "ONG Sul")
    other = BankAccount.create_for(organization: foreign, name: "Conta Estranha", compe: "001")
    inactive = BankAccount.create_for(organization: organization, name: "Conta Morta", compe: "237")
    inactive.update!(active: false)

    get "/months/2026-05/matches", params: { bank_account_id: 0 }
    expect(response).to have_http_status(:not_found)

    get "/months/2026-05/matches", params: { bank_account_id: other.id }
    expect(response).to have_http_status(:not_found)

    get "/months/2026-05/matches", params: { bank_account_id: inactive.id }
    expect(response).to have_http_status(:not_found)
  end

  it "GET matches shows current payment and its selected suggestion" do
    account, organization, _month, statement = signed_month
    statement.bank_account.update!(name: "Conta Principal")
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central", occurred_on: Date.new(2026, 5, 11))
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    get "/months/2026-05/matches"
    doc = page_doc(response.body)
    payment = doc.at_css('[data-current="true"]')
    expect(payment.text).to include("11/05", "Pix enviado — Padaria Central", "Conta Principal", "R$ 220,00")
    expect(payment.at_css('input[checked]')).to be_present
    document = doc.at_css('[data-row="pool-document"]')
    expect(document.text).to include("Padaria Central", "R$ 220,00")
    expect(document.at_css('input[checked]')).to be_present
  end

  it "GET matches completed row includes payee observation and undo" do
    account, organization, month, statement = signed_month
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central", occurred_on: Date.new(2026, 5, 11))
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "200,00")
    match = Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ], observation: "desconto não documentado")
    get "/months/2026-05/matches"
    row = page_doc(response.body).at_css("[data-match-id='#{match.id}']")
    expect(row.text).to include("Padaria Central", "desconto não documentado", "Desfazer casamento")
    expect(row.at_css('input[type="checkbox"]')).to be_nil
  end

  it "GET matches exception rows offer unmark for each type" do
    _account, organization, _month, statement = signed_month
    extra = ExtraExceptionKind.create_for(organization: organization, name: "Doação", justification: "Isento de documento de suporte.")
    [ [ "Tarifa bancária", proc { |p| p.mark_document_exception("bank_fee") } ],
      [ "Honorário do contador", proc { |p| p.mark_document_exception("accountant_fee") } ],
      [ extra.name, proc { |p| p.mark_document_exception(extra_exception_kind_id: extra.id) } ] ].each do |label, mark|
      payment = plant_payment(statement, 22000, history: "Pix #{label}")
      mark.call(payment)
      get "/months/2026-05/matches"
      row = page_doc(response.body).at_css("[data-exception-payment-id='#{payment.id}']")
      expect(row.text).to include(label, "Desmarcar exceção")
    end
  end

  it "GET matches orders pending payments by date then id" do
    _account, _organization, _month, statement = signed_month
    later = plant_payment(statement, 10000, history: "Depois", occurred_on: Date.new(2026, 5, 12))
    earlier = plant_payment(statement, 10000, history: "Antes", occurred_on: Date.new(2026, 5, 11))
    same_b = plant_payment(statement, 10000, history: "Mesmo B", occurred_on: Date.new(2026, 5, 11))
    same_a = plant_payment(statement, 10000, history: "Mesmo A", occurred_on: Date.new(2026, 5, 11))
    get "/months/2026-05/matches"
    ids = page_doc(response.body).css('[data-row="payment"]').map { |node| node["data-payment-id"].to_i }
    expect(ids).to eq([ earlier.id, same_b.id, same_a.id, later.id ])
    expect(page_doc(response.body).at_css('[data-current="true"]')["data-payment-id"]).to eq(earlier.id.to_s)
  end

  it "GET matches lists eligible documents oldest first and excludes other months" do
    account, organization, month, statement = signed_month
    plant_payment(statement, 10000)
    april, = plant_month(organization, year_month: "2026-04")
    first = plant_recibo(organization, account, payee: "Padaria", amount: "100,00", date: "2026-05-11")
    last = plant_recibo(organization, account, payee: "Mercado", amount: "180,00", date: "2026-05-12")
    same_month = plant_recibo(organization, account, payee: "No Pacote", amount: "50,00", date: "2026-05-10")
    same_month.update!(month_id: month.id)
    other = plant_recibo(organization, account, payee: "Outro Mês", amount: "30,00", date: "2026-04-01")
    other.update!(month_id: april.id)
    get "/months/2026-05/matches"
    rows = page_doc(response.body).css('[data-row="pool-document"]')
    expect(rows.map { |row| row["data-document-id"].to_i }).to eq([ same_month.id, first.id, last.id ])
    expect(rows.map(&:text).join).not_to include("Outro Mês")
    get "/supporting_documents"
    entries = page_doc(response.body).css('li[data-row="document"]').map(&:text).join
    expect(entries).to include("Padaria", "Mercado")
  end

  it "GET matches shows empty document selection when no documents exist" do
    _account, _organization, _month, statement = signed_month
    plant_payment(statement, 10000)
    get "/months/2026-05/matches"
    expect(response.body).to include("Nenhum documento selecionado")
    expect(page_doc(response.body).css('[data-row="pool-document"]')).to be_empty
  end

  it "GET matches form includes observation and active exception choices" do
    _account, organization, _month, statement = signed_month
    plant_payment(statement, 10000)
    ExtraExceptionKind.create_for(organization: organization, name: "Zebra", justification: "Isento de documento de suporte.")
    ExtraExceptionKind.create_for(organization: organization, name: "Doação", justification: "Isento de documento de suporte.")
    get "/months/2026-05/matches"
    confirm = confirm_form(response.body)
    expect(confirm).to be_present
    expect(confirm.text).to include("Pagamentos", "Documentos", "Observação do casamento")
    expect(confirm.at_css("textarea")["class"]).to include("border-rule")
    expect(confirm.at_css('input[type="submit"]')["value"]).to eq("Confirmar casamento")
    expect(confirm.text).to include("Escolher exceção", "Tarifa bancária", "Honorário do contador", "Doação", "Zebra")
  end

  it "GET matches preselects Padaria 1:1 without confirming" do
    account, organization, _month, statement = signed_month
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central", occurred_on: Date.new(2026, 5, 11))
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00", date: "2026-05-11")
    get "/months/2026-05/matches"
    doc = page_doc(response.body)
    expect(doc.at_css("[data-payment-id='#{payment.id}']").text).to include("11/05", "Pix enviado — Padaria Central", "R$ 220,00")
    expect(doc.at_css("[data-document-id='#{document.id}']").text).to include("11/05", "Padaria Central", "R$ 220,00")
    expect(doc.at_css("[data-document-id='#{document.id}'] input[checked]")).to be_present
    expect(Match.count).to eq(0)
  end

  it "GET matches pending queue ignores catalog debit" do
    account, organization, _month, statement = signed_month
    plant_payment(statement, 22000, history: "Transferência — BB Rende Fácil")
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central", occurred_on: Date.new(2026, 5, 11))
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    get "/months/2026-05/matches"
    expect(response.body).not_to include("Transferência — BB Rende Fácil")
    expect(page_doc(response.body).at_css('[data-current="true"]').text).to include("Pix enviado — Padaria Central")
  end

  it "GET matches selects earlier Fornecedor Norte payment" do
    account, organization, _month, statement = signed_month
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central", occurred_on: Date.new(2026, 5, 11))
    plant_payment(statement, 22000, history: "TED — Fornecedor Norte", occurred_on: Date.new(2026, 5, 4))
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    plant_recibo(organization, account, payee: "Fornecedor Norte", amount: "220,00")
    get "/months/2026-05/matches"
    row = page_doc(response.body).at_css('[data-current="true"]')
    expect(row.text).to include("TED — Fornecedor Norte")
    expect(row.text).not_to include("Pix enviado — Padaria Central")
  end

  it "GET matches current payment follows Principal account filter" do
    account, organization, _month, _alfa, principal, alfa_statement, principal_statement = two_account_month
    plant_payment(principal_statement, 22000, history: "Pix enviado — Padaria Central", occurred_on: Date.new(2026, 5, 11))
    plant_payment(alfa_statement, 22000, history: "TED — Fornecedor Norte", occurred_on: Date.new(2026, 5, 4))
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    get "/months/2026-05/matches", params: { bank_account_id: principal.id }
    row = page_doc(response.body).at_css('[data-current="true"]')
    expect(row.text).to include("Pix enviado — Padaria Central")
    expect(row.text).not_to include("Fornecedor Norte")
  end

  it "GET matches suggestion 1:N displays both selected documents" do
    account, organization, _month, statement = signed_month
    plant_payment(statement, 15500, history: "Pix papelaria")
    first = plant_recibo(organization, account, payee: "Papelaria Norte", amount: "100,00", date: "2026-05-13")
    second = plant_recibo(organization, account, payee: "Papelaria Norte", amount: "55,00", date: "2026-05-14")
    Justification.declare(organization: organization, account: account, amount: "155,00", supporting_document_ids: [ first.id, second.id ])
    get "/months/2026-05/matches"
    rows = page_doc(response.body).css('[data-row="pool-document"]')
    expect(rows.map { |row| row["data-document-id"].to_i }).to eq([ first.id, second.id ])
    expect(rows.map { |row| row.at_css("input[checked]") }).to all(be_present)
    expect(rows.map(&:text).join).to include("13/05", "14/05", "R$ 100,00", "R$ 55,00")
  end

  it "GET matches still includes exception suggestion for current payment" do
    _account, organization, _month, statement = signed_month
    organization.update!(accountant_pix_key: "chave-pix")
    plant_payment(statement, 22000, history: "Pix enviado chave-pix")
    get "/months/2026-05/matches"
    expect(response.body).to include("Pix enviado chave-pix", "Sugestão de exceção")
  end

  it "GET matches shows current payment when only exception suggestion remains" do
    _account, organization, _month, statement = signed_month
    organization.update!(accountant_pix_key: "chave-pix")
    plant_payment(statement, 22000, history: "Pix enviado chave-pix")
    get "/months/2026-05/matches"
    expect(page_doc(response.body).at_css('[data-current="true"]').text).to include("Pix enviado chave-pix")
    expect(response.body).to include("Sugestão de exceção", "Nenhum documento selecionado")
    expect(confirm_form(response.body)).to be_present
  end

  it "GET matches omits next suggestion when only format_2 remains" do
    account, organization, _month, statement = signed_month
    plant_payment(statement, 10000, history: "Dez")
    plant_payment(statement, 12000, history: "Doze")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05/matches"

    expect(matches_h2s(response.body)).not_to include("Próxima sugestão")
    expect(confirm_form(response.body)).to be_present
  end

  it "GET matches dates are day month and month page keeps the year" do
    account, organization, _month, statement = signed_month
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central", occurred_on: Date.new(2026, 5, 11))
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00", date: "2026-05-11")

    get "/months/2026-05/matches"

    page_doc(response.body).css('li[data-row="payment"] time, li[data-row="pool-document"] time').each do |node|
      expect(node.text.strip).to eq("11/05")
      expect(node["datetime"]).to eq("2026-05-11")
    end

    get "/months/2026-05"
    pay = page_doc(response.body).css('li[data-row="payment"]').find { |node|
      node.text.include?("Pix enviado — Padaria Central")
    }
    expect(pay.at_css("time").text.strip).to eq("11/05/2026")
    expect(pay.at_css("time")["datetime"]).to eq("2026-05-11")
  end

  it "POST matches from this screen 302s here Casado and drops pool payee" do
    account, organization, _month, statement = signed_month
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    post "/months/2026-05/matches", params: {
      screen: "matches",
      payment_ids: [ payment.id ],
      supporting_document_ids: [ document.id ]
    }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05/matches")
    expect(Match.count).to eq(1)

    get "/months/2026-05/matches"
    row = page_doc(response.body).at_css("[data-match-id]")
    expect(row.text).to include("Padaria Central")
    expect(page_doc(response.body).at_css('[data-row="pool-document"]')).to be_nil
  end

  it "POST matches N:1 from this screen 302s here both Casado" do
    account, organization, _month, statement = signed_month
    ten = plant_payment(statement, 10000, history: "Dez")
    twelve = plant_payment(statement, 12000, history: "Doze")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    post "/months/2026-05/matches", params: {
      screen: "matches",
      payment_ids: [ ten.id, twelve.id ],
      supporting_document_ids: [ document.id ]
    }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05/matches")
    get "/months/2026-05/matches"
    row = page_doc(response.body).at_css("[data-match-id]")
    expect(row.text).to include("Dez", "Doze")
  end

  it "POST matches N:M from this screen 422s matches with BAD_SHAPE" do
    account, organization, _month, statement = signed_month
    pay_a = plant_payment(statement, 10000, history: "A")
    pay_b = plant_payment(statement, 12000, history: "B")
    doc_a = plant_recibo(organization, account, payee: "Padaria A", amount: "100,00")
    doc_b = plant_recibo(organization, account, payee: "Padaria B", amount: "120,00")

    post "/months/2026-05/matches", params: {
      screen: "matches",
      payment_ids: [ pay_a.id, pay_b.id ],
      supporting_document_ids: [ doc_a.id, doc_b.id ]
    }

    expect(Match.count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    expect(page_doc(response.body).at_css("h1").text.strip).to eq("Casar pagamentos")
    expect(response.body).not_to include("Fechar para envio")
    expect(error_notice_text(response.body)).to eq(
      "Casamento é um pagamento com um ou mais documentos, ou vários pagamentos com um documento"
    )
  end

  it "POST matches lesser blank observation 422s matches with border-rule" do
    account, organization, _month, statement = signed_month
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "200,00")

    post "/months/2026-05/matches", params: {
      screen: "matches",
      payment_ids: [ payment.id ],
      supporting_document_ids: [ document.id ]
    }

    expect(Match.count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Informe a observação do casamento")
    expect(page_doc(response.body).at_css("h1").text.strip).to eq("Casar pagamentos")
    observation = page_doc(response.body).at_css("#match-confirm textarea")
    expect(observation["class"]).to include("border-rule")
  end

  it "POST matches lesser Aluguel blank observation 422s Informe a observacao" do
    account, organization, _month, statement = signed_month
    payment = plant_payment(statement, 150000, history: "TED — Aluguel sede")
    document = plant_recibo(organization, account, payee: "Imobiliária Serra", amount: "1400,00")

    post "/months/2026-05/matches", params: {
      screen: "matches",
      payment_ids: [ payment.id ],
      supporting_document_ids: [ document.id ]
    }

    expect(Match.count).to eq(0)
    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Informe a observação do casamento")
    expect(page_doc(response.body).at_css('[data-notice="error"]').text.strip).to eq(
      "Informe a observação do casamento"
    )
  end

  it "POST matches lesser Aluguel with observation 302s Casado" do
    account, organization, _month, statement = signed_month
    payment = plant_payment(statement, 150000, history: "TED — Aluguel sede")
    document = plant_recibo(organization, account, payee: "Imobiliária Serra", amount: "1400,00")

    post "/months/2026-05/matches", params: {
      screen: "matches",
      payment_ids: [ payment.id ],
      supporting_document_ids: [ document.id ],
      observation: "desconto não documentado"
    }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05/matches")
    get "/months/2026-05/matches"
    row = page_doc(response.body).at_css("[data-match-id]")
    expect(row.text).to include("TED — Aluguel sede", "desconto não documentado")
  end

  it "POST matches from filtered screen keeps bank_account_id" do
    account, organization, _month, _alfa, principal, _alfa_statement, principal_statement = two_account_month
    payment = plant_payment(principal_statement, 22000, history: "Pix enviado — Padaria Central")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    post "/months/2026-05/matches", params: {
      screen: "matches",
      bank_account_id: principal.id,
      payment_ids: [ payment.id ],
      supporting_document_ids: [ document.id ]
    }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05/matches?bank_account_id=#{principal.id}")
  end

  it "POST matches omitting screen still 302s month" do
    account, organization, _month, statement = signed_month
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    post "/months/2026-05/matches", params: {
      payment_ids: [ payment.id ],
      supporting_document_ids: [ document.id ]
    }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
  end

  it "month GET still has Resolver and N:1 fold after matches screen exists" do
    account, organization, _month, statement = signed_month
    plant_payment(statement, 10000, history: "Um")
    plant_payment(statement, 12000, history: "Dois")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    expect(response.body).not_to include("Resolver")
    expect(response.body).not_to include("Casar vários pagamentos com um documento")
  end

  it "POST exception from matches strip with one payment stays here" do
    _account, organization, _month, _alfa, principal, _alfa_statement, principal_statement = two_account_month
    extra = ExtraExceptionKind.create_for(organization: organization, name: "Doação", justification: "Isento de documento de suporte.")
    payment = plant_payment(principal_statement, 22000, history: "Pix tarifa")

    post "/months/2026-05/document_exceptions", params: {
      screen: "matches",
      bank_account_id: principal.id,
      payment_ids: [ payment.id ],
      kind: "bank_fee"
    }

    expect(payment.reload.document_exception_kind).to eq("bank_fee")
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05/matches?bank_account_id=#{principal.id}")
    get "/months/2026-05/matches", params: { bank_account_id: principal.id }
    row = page_doc(response.body).at_css("[data-exception-payment-id]")
    expect(row.text).to include("Tarifa bancária", "Desmarcar exceção")

    honor = plant_payment(principal_statement, 22000, history: "Pix honorario")
    post "/months/2026-05/document_exceptions", params: {
      screen: "matches", payment_ids: [ honor.id ], kind: "accountant_fee"
    }
    expect(honor.reload.document_exception_kind).to eq("accountant_fee")
    expect(response).to redirect_to("/months/2026-05/matches")

    gift = plant_payment(principal_statement, 22000, history: "Pix extra")
    post "/months/2026-05/document_exceptions", params: {
      screen: "matches", payment_ids: [ gift.id ], extra_exception_kind_id: extra.id
    }
    expect(gift.reload.extra_exception_kind_id).to eq(extra.id)
    expect(response).to redirect_to("/months/2026-05/matches")
  end

  it "POST exception from matches strip with zero or two payments 422s selection notice" do
    _account, _organization, _month, statement = signed_month
    one = plant_payment(statement, 22000, history: "Um")
    two = plant_payment(statement, 18000, history: "Dois")

    post "/months/2026-05/document_exceptions", params: {
      screen: "matches", kind: "bank_fee"
    }
    expect(one.reload.missing_document?).to eq(true)
    expect(response).to have_http_status(:unprocessable_content)
    expect(page_doc(response.body).at_css("h1").text.strip).to eq("Casar pagamentos")
    expect(error_notice_text(response.body)).to eq("Selecione um pagamento para marcar a exceção.")

    post "/months/2026-05/document_exceptions", params: {
      screen: "matches", payment_ids: [ one.id, two.id ], kind: "bank_fee"
    }
    expect(one.reload.missing_document?).to eq(true)
    expect(two.reload.missing_document?).to eq(true)
    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Selecione um pagamento para marcar a exceção.")
  end

  it "GET matches omits inactive exception choices" do
    _account, organization, _month, statement = signed_month
    organization.update!(bank_fee_exception_active: false, accountant_fee_exception_active: false)
    extra = ExtraExceptionKind.create_for(organization: organization, name: "Doação", justification: "Isento de documento de suporte.")
    extra.apply_active(false)
    plant_payment(statement, 10000)
    get "/months/2026-05/matches"
    expect(response.body).not_to include("Escolher exceção", "Tarifa bancária", "Honorário do contador", "Doação")
  end

  it "undo casamento and exception from matches stay here without turbo-confirm" do
    account, organization, month, statement = signed_month
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    match = Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])

    get "/months/2026-05/matches"
    undo = page_doc(response.body).css("button").find { |node| node.text.strip == "Desfazer casamento" }
    expect(undo["data-turbo-confirm"]).to be_nil
    expect(undo.ancestors.find { |node| node["data-turbo-confirm"] }).to be_nil

    delete "/months/2026-05/matches/#{match.id}", params: { screen: "matches" }

    expect(Match.count).to eq(0)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05/matches")

    filtered = Match.confirm(month: month, payments: [ payment.reload ], supporting_documents: [ document.reload ])
    delete "/months/2026-05/matches/#{filtered.id}", params: { screen: "matches", bank_account_id: statement.bank_account_id }
    expect(response).to redirect_to("/months/2026-05/matches?bank_account_id=#{statement.bank_account_id}")
    get "/months/2026-05/matches"
    expect(page_doc(response.body).at_css('[data-current="true"]').text).to include("Padaria Central")
    expect(page_doc(response.body).at_css('[data-row="pool-document"]').text).to include("Padaria Central")

    fee = plant_payment(statement, 15000, history: "Tarifa")
    fee.mark_document_exception("bank_fee")
    get "/months/2026-05/matches"
    clear = page_doc(response.body).css("button").find { |node| node.text.strip == "Desmarcar exceção" }
    expect(clear["data-turbo-confirm"]).to be_nil
    expect(clear.ancestors.find { |node| node["data-turbo-confirm"] }).to be_nil

    delete "/months/2026-05/payments/#{fee.id}/document_exception", params: {
      screen: "matches", bank_account_id: statement.bank_account_id
    }
    expect(response).to redirect_to("/months/2026-05/matches?bank_account_id=#{statement.bank_account_id}")
    expect(fee.reload.missing_document?).to eq(true)
  end

  it "GET matches closed shows exceptions without mutation controls" do
    account, organization, month, statement = signed_month
    ExtraExceptionKind.create_for(organization: organization, name: "Doação", justification: "Isento de documento de suporte.")
    payment = plant_payment(statement, 22000, occurred_on: Date.new(2026, 5, 11))
    payment.mark_document_exception("bank_fee")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00", date: "2026-05-11")
    document.update!(month_id: month.id)
    month.update!(closed: true)
    get "/months/2026-05/matches"
    expect(response).to have_http_status(:ok)
    doc = page_doc(response.body)
    expect(doc.at_css("h1").text.strip).to eq("Casar pagamentos")
    expect(doc.text).to include("Voltar ao mês", "Tarifa bancária", "Exceções marcadas")
    expect(doc.at_css('input[type="checkbox"]')).to be_nil
    expect(doc.text).not_to include("Confirmar casamento", "Escolher exceção", "Desmarcar exceção", "Desfazer casamento")
    expect(doc.at_css('[data-stamp="closed"]')).to be_nil
  end

  it "GET matches unconfirmed open is 404" do
    _account, _organization, _month, _statement = signed_month
    Month.find_by!(year_month: "2026-05").update!(accounts_confirmed: false)

    get "/months/2026-05/matches"

    expect(response).to have_http_status(:not_found)
  end

  it "GET matches unauthenticated 302 login submitter and unknown month 404" do
    get "/months/2026-05/matches"
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")

    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    _month, statement = plant_month(organization)
    plant_payment(statement, 15500, history: "PIX Isolado")
    sign_in_as(submitter, organization: organization)

    get "/months/2026-05/matches"
    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include("PIX Isolado")

    account, org = plant_coordinator(email: "coord2@example.com", organization_name: "ONG Dois")
    sign_in_as(account, organization: org)
    plant_month(org)

    get "/months/2026-13/matches"
    expect(response).to have_http_status(:not_found)

    get "/months/2026-06/matches"
    expect(response).to have_http_status(:not_found)
  end

  it "POST strip exception on unconfirmed month returns 404" do
    _account, _organization, month, statement = signed_month
    month.update!(accounts_confirmed: false)
    payment = plant_payment(statement, 22000)

    post "/months/2026-05/document_exceptions", params: {
      screen: "matches", payment_ids: [ payment.id ], kind: "bank_fee"
    }

    expect(response).to have_http_status(:not_found)
    expect(payment.reload.missing_document?).to eq(true)
  end

  it "POST strip exception while closed returns 422 Mes fechado" do
    _account, _organization, month, statement = signed_month
    payment = plant_payment(statement, 22000)
    month.update!(closed: true)

    post "/months/2026-05/document_exceptions", params: {
      screen: "matches", payment_ids: [ payment.id ], kind: "bank_fee"
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Mês fechado")
    expect(payment.reload.missing_document?).to eq(true)
  end
end
