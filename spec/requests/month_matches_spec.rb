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

  it "GET matches chrome is month title Voltar and omits Fechar Recebimentos stamp" do
    signed_month

    get "/months/2026-05/matches"

    expect(response).to have_http_status(:ok)
    doc = page_doc(response.body)
    expect(doc.at_css("h1").text.strip).to eq("maio de 2026")
    meta = doc.at_css("h1").parent.at_css("p")
    expect(meta.text.strip).to eq("2026-05")
    expect(meta["class"]).to include("text-meta")
    expect(meta["class"]).to include("text-ink-soft")
    back = doc.css("a").find { |node| node.text.strip == "Voltar ao mês" }
    expect(back["href"]).to eq("/months/2026-05")
    cluster = doc.at_css("h1").parent.parent
    expect(cluster["class"]).to include("justify-between")
    cluster_kids = cluster.element_children
    expect(cluster_kids[0].at_css("h1").text.strip).to eq("maio de 2026")
    expect(cluster_kids[1].text.strip).to eq("Voltar ao mês")
    expect(response.body).not_to include("Fechar para envio")
    expect(matches_h2s(response.body)).not_to include("Recebimentos")
    expect(doc.at_css('[data-stamp="closed"]')).to be_nil
  end

  it "GET matches Pagamentos precedes pool inside match-split and omits close Devolver" do
    signed_month

    get "/months/2026-05/matches"

    doc = page_doc(response.body)
    split = doc.at_css(".match-split")
    expect(split).to be_present
    headings = split.css("h2").map { |node| node.text.strip }
    expect(headings).to eq([ "Pagamentos", "Documentos sem casamento" ])
    regions = doc.at_css("[data-controller='month-match']").element_children
    chip_at = regions.index { |node| node["role"] == "group" }
    count_at = regions.index { |node| node.name == "p" && node.text.include?("documento faltante") }
    split_at = regions.index { |node| node["class"].to_s.split.include?("match-split") }
    expect(chip_at).to be < count_at
    expect(count_at).to be < split_at
    expect(doc.at_css("form#close-month")).to be_nil
    controls = page_doc(response.body).css("a, button, input[type='submit']").map { |node| (node["value"] || node.text).strip }
    expect(controls).not_to include("Devolver")
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

  it "GET matches filter Principal hides Alfa payment and keeps Padaria in pool" do
    account, organization, _month, _alfa, principal, alfa_statement, principal_statement = two_account_month
    plant_payment(principal_statement, 22000, history: "Pix enviado — Padaria Central")
    plant_payment(alfa_statement, 45000, history: "TED — Energia Ltda")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05/matches", params: { bank_account_id: principal.id }

    current = chip_links(response.body).find { |node| node["aria-current"] == "true" }
    expect(current.text.strip).to eq("Conta Principal")
    todas = chip_links(response.body).find { |node| node.text.strip == "Todas" }
    expect(todas["aria-current"]).to be_nil
    pay = pagamentos_section(response.body)
    expect(pay.text).to include("Pix enviado — Padaria Central")
    expect(pay.text).to include("Conta Principal")
    expect(pay.text).not_to include("TED — Energia Ltda")
    summary = page_doc(response.body).css("p, span").find { |node| node.text.include?("documento faltante") }
    expect(summary.text.strip).to eq("1 pagamento com documento faltante.")
    expect(summary["class"]).to include("text-margem")
    expect(pool_section(response.body).text).to include("Padaria Central")
  end

  it "GET matches unfiltered missing count is two and filtered none omits margem" do
    _account, _organization, _month, _alfa, principal, alfa_statement, principal_statement = two_account_month
    plant_payment(principal_statement, 22000, history: "Pix enviado — Padaria Central")
    plant_payment(alfa_statement, 45000, history: "TED — Energia Ltda")

    get "/months/2026-05/matches"

    two = page_doc(response.body).css("p, span").find { |node| node.text.include?("documento faltante") }
    expect(two.text.strip).to eq("2 pagamentos com documento faltante.")
    expect(two["class"]).to include("text-margem")

    plant_payment(principal_statement, 10000, history: "Tarifa").mark_document_exception("bank_fee")
    Payment.find_by!(history: "Pix enviado — Padaria Central").mark_document_exception("bank_fee")

    get "/months/2026-05/matches", params: { bank_account_id: principal.id }

    none = page_doc(response.body).css("p, span").find { |node| node.text.include?("documento faltante") }
    expect(none.text.strip).to eq("Nenhum documento faltante.")
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

  it "GET matches missing payment checkbox suggestion and no Resolver" do
    account, organization, _month, statement = signed_month
    statement.bank_account.update!(name: "Conta Principal")
    organization.update!(accountant_pix_key: "chave-pix")
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central", occurred_on: Date.new(2026, 5, 11))
    plant_payment(statement, 15000, history: "Pix enviado chave-pix", occurred_on: Date.new(2026, 5, 12))
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05/matches"

    row = page_doc(response.body).css('li[data-row="payment"][data-status="missing"]').find { |node|
      node.text.include?("Pix enviado — Padaria Central")
    }
    expect(row["class"]).to include("is-block")
    first = row.element_children.first
    expect(first.at_css('input[type="checkbox"]')).to be_present
    expect(row.at_css("time").text.strip).to eq("11/05/2026")
    expect(row.text).to include("Pix enviado — Padaria Central")
    expect(row.text).to include("Conta Principal")
    expect(row.text).to include("R$ 220,00")
    faltante = row.css("p").find { |node| node.text.strip == "Documento faltante" }
    expect(faltante["class"]).to include("text-margem")
    expect(row.text).to include("Sugestão Padaria Central")
    expect(row.text).not_to include("Sugestão de exceção")
    expect(row.text).not_to include("Resolver")
    css = Rails.root.join("app/assets/tailwind/application.css").read
    expect(css).to match(/\.ledger-row\.is-block\s*\{\s*border-left:\s*3px solid var\(--color-margem\)/m)
    exception_row = page_doc(response.body).css('li[data-row="payment"][data-status="missing"]').find { |node|
      node.text.include?("Pix enviado chave-pix")
    }
    expect(exception_row.text).to include("Sugestão de exceção")
    expect(exception_row.text).to include("Documento faltante")
  end

  it "GET matches Casado row is times undo with payee observation and no checkbox" do
    account, organization, month, statement = signed_month
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central", occurred_on: Date.new(2026, 5, 11))
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "200,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ], observation: "desconto não documentado")

    get "/months/2026-05/matches"

    row = page_doc(response.body).at_css('li[data-row="payment"][data-status="matched"]')
    first = row.element_children.first
    undo = first.at_css('[aria-label="Desfazer casamento"]')
    expect(undo.text.strip).to eq("×")
    expect(undo["class"]).to include("text-margem")
    expect(row.at_css('input[type="checkbox"]')).to be_nil
    expect(row.text).to include("Casado")
    expect(row.text).to include("Padaria Central")
    expect(row.text).to include("desconto não documentado")
    expect(row.text).not_to include("Ações")
  end

  it "GET matches exception row times Desmarcar excecao" do
    _account, organization, _month, statement = signed_month
    extra = ExtraExceptionKind.create_for(organization: organization, name: "Doação", justification: "Isento de documento de suporte.")

    [
      [ "bank_fee", "Tarifa bancária", proc { |payment| payment.mark_document_exception("bank_fee") } ],
      [ "accountant_fee", "Honorário do contador", proc { |payment| payment.mark_document_exception("accountant_fee") } ],
      [ "extra", extra.name, proc { |payment| payment.mark_document_exception(extra_exception_kind_id: extra.id) } ]
    ].each do |status, label, mark|
      payment = plant_payment(statement, 22000, history: "Pix #{status}")
      mark.call(payment)

      get "/months/2026-05/matches"

      row = page_doc(response.body).at_css(%(li[data-row="payment"][data-status="#{status}"]))
      expect(row.text).to include(label)
      undo = row.element_children.first.at_css('[aria-label="Desmarcar exceção"]')
      expect(undo.text.strip).to eq("×")
      expect(row.text).not_to include("Resolver")
    end
  end

  it "GET matches payments follow occurred_on id and omit N:1 fold" do
    _account, _organization, _month, statement = signed_month
    later = plant_payment(statement, 10000, history: "Depois", occurred_on: Date.new(2026, 5, 12))
    earlier = plant_payment(statement, 10000, history: "Antes", occurred_on: Date.new(2026, 5, 11))
    same_b = plant_payment(statement, 10000, history: "Mesmo B", occurred_on: Date.new(2026, 5, 11))
    same_a = plant_payment(statement, 10000, history: "Mesmo A", occurred_on: Date.new(2026, 5, 11))

    get "/months/2026-05/matches"

    ids = page_doc(response.body).css('li[data-row="payment"]').map { |node| node["data-payment-id"].to_i }
    expect(ids).to eq([ earlier.id, same_b.id, same_a.id, later.id ])
    expect(response.body).not_to include("Casar vários pagamentos com um documento")
  end

  it "GET matches pool rows checkbox date payee amount tipo in listed order" do
    account, organization, month, _statement = signed_month
    april, _april_statement = plant_month(organization, year_month: "2026-04")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00", date: "2026-05-11")
    SupportingDocument.insert(
      organization: organization,
      account: account,
      kind: "nota_fiscal",
      amount: "180,00",
      date: "2026-05-12",
      payee: "Mercado Silva",
      photo: photo_named("nota-mercado-silva.jpg")
    )
    packaged = plant_recibo(organization, account, payee: "No Pacote", amount: "50,00", date: "2026-05-10")
    packaged.update!(month_id: month.id)
    other_month = plant_recibo(organization, account, payee: "Outro Mês", amount: "30,00", date: "2026-04-01")
    other_month.update!(month_id: april.id)

    get "/months/2026-05/matches"

    rows = page_doc(response.body).css('li[data-row="pool-document"]')
    payees = rows.map { |node| node.at_css("label, p.font-medium")&.text&.strip }
    expect(payees).to eq([ "Mercado Silva", "Padaria Central", "No Pacote" ])
    expect(payees).not_to include("Outro Mês")
    expect(rows[0].at_css('input[type="checkbox"]')).to be_present
    expect(rows[0].at_css("time").text.strip).to eq("12/05/2026")
    expect(rows[0].text).to include("Mercado Silva")
    expect(rows[0].text).to include("R$ 180,00")
    expect(rows[0].text).to include("Nota fiscal")
    expect(rows[1].at_css("time").text.strip).to eq("11/05/2026")
    expect(rows[1].text).to include("Padaria Central")
    expect(rows[1].text).to include("R$ 220,00")
    expect(rows[1].text).to include("Recibo")

    month.update!(closed: true)
    get "/months/2026-05/matches"
    closed_payees = page_doc(response.body).css('li[data-row="pool-document"]').map { |node|
      node.at_css("label, p.font-medium")&.text&.strip
    }
    expect(closed_payees).to eq([ "No Pacote" ])
  end

  it "GET matches empty pool copy and no pool rows" do
    signed_month

    get "/months/2026-05/matches"

    expect(response.body).to include("Nenhum documento sem casamento")
    expect(page_doc(response.body).css('li[data-row="pool-document"]')).to be_empty
  end

  it "GET matches totaling line confirm marks and observation border-rule" do
    _account, organization, _month, _statement = signed_month
    ExtraExceptionKind.create_for(organization: organization, name: "Zebra", justification: "Isento de documento de suporte.")
    ExtraExceptionKind.create_for(organization: organization, name: "Doação", justification: "Isento de documento de suporte.")

    get "/months/2026-05/matches"

    doc = page_doc(response.body)
    confirm = doc.at_css(".match-confirm")
    expect(confirm).to be_present
    regions = doc.at_css("[data-controller='month-match']").element_children
    split_at = regions.index { |node| node["class"].to_s.split.include?("match-split") }
    confirm_at = regions.index { |node| node["id"] == "match-confirm" || node["class"].to_s.split.include?("match-confirm") }
    expect(split_at).to be < confirm_at
    css = Rails.root.join("app/assets/tailwind/application.css").read
    expect(css).to match(/\.match-confirm\s*\{[^}]*border-top:\s*1px solid var\(--color-ink\)/m)
    expect(confirm.text).to include("Pagamentos")
    expect(confirm.text).to include("Documentos")
    expect(confirm.at_css("label")&.text).to include("Observação do casamento")
    observation = confirm.at_css("textarea")
    expect(observation["class"]).to include("border-rule")
    expect(observation["class"]).not_to include("margem")
    submits = confirm.css('input[type="submit"], button').map { |node|
      label = node.text.strip
      label.present? ? label : node["value"].to_s.strip
    }
    expect(submits).to include("Confirmar casamento")
    tarifa_at = submits.index("Marcar tarifa")
    honorario_at = submits.index("Marcar honorário")
    doacao_at = submits.index("Doação")
    zebra_at = submits.index("Zebra")
    confirm_at = submits.index("Confirmar casamento")
    expect(confirm_at).to be < tarifa_at
    expect(tarifa_at).to be < honorario_at
    expect(honorario_at).to be < doacao_at
    expect(doacao_at).to be < zebra_at
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
    row = page_doc(response.body).at_css('li[data-row="payment"]')
    expect(row["data-status"]).to eq("matched")
    expect(row.text).to include("Casado")
    expect(pool_section(response.body).text).not_to include("Padaria Central")
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
    expect(payment_row_html(response.body, history: "Dez")).to include("Casado")
    expect(payment_row_html(response.body, history: "Doze")).to include("Casado")
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
    expect(page_doc(response.body).at_css("h1").text.strip).to eq("maio de 2026")
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
    expect(page_doc(response.body).at_css("h1").text.strip).to eq("maio de 2026")
    observation = page_doc(response.body).at_css(".match-confirm textarea")
    expect(observation["class"]).to include("border-rule")
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
    row = page_doc(response.body).at_css('li[data-row="payment"][data-status="bank_fee"]')
    expect(row.text).to include("Tarifa bancária")
    expect(row.at_css('[aria-label="Desmarcar exceção"]').text.strip).to eq("×")

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
    expect(page_doc(response.body).at_css("h1").text.strip).to eq("maio de 2026")
    expect(error_notice_text(response.body)).to eq("Selecione um pagamento para marcar a exceção.")

    post "/months/2026-05/document_exceptions", params: {
      screen: "matches", payment_ids: [ one.id, two.id ], kind: "bank_fee"
    }
    expect(one.reload.missing_document?).to eq(true)
    expect(two.reload.missing_document?).to eq(true)
    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Selecione um pagamento para marcar a exceção.")
  end

  it "GET matches omits inactive exception mark buttons" do
    _account, organization, _month, _statement = signed_month
    organization.update!(bank_fee_exception_active: false, accountant_fee_exception_active: false)
    extra = ExtraExceptionKind.create_for(organization: organization, name: "Doação", justification: "Isento de documento de suporte.")
    extra.apply_active(false)

    get "/months/2026-05/matches"

    confirm = page_doc(response.body).at_css(".match-confirm")
    labels = confirm.css('input[type="submit"], button').map { |node|
      label = node.text.strip
      label.present? ? label : node["value"].to_s.strip
    }
    expect(labels).not_to include("Marcar tarifa")
    expect(labels).not_to include("Marcar honorário")
    expect(labels).not_to include("Doação")
  end

  it "undo casamento and exception from matches stay here without turbo-confirm" do
    account, organization, month, statement = signed_month
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    match = Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])

    get "/months/2026-05/matches"
    undo = page_doc(response.body).at_css('[aria-label="Desfazer casamento"]')
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
    expect(page_doc(response.body).at_css('li[data-row="payment"][data-status="missing"]').text).to include("Documento faltante")
    expect(pool_section(response.body).text).to include("Padaria Central")

    fee = plant_payment(statement, 15000, history: "Tarifa")
    fee.mark_document_exception("bank_fee")
    get "/months/2026-05/matches"
    clear = page_doc(response.body).at_css('[aria-label="Desmarcar exceção"]')
    expect(clear["data-turbo-confirm"]).to be_nil
    expect(clear.ancestors.find { |node| node["data-turbo-confirm"] }).to be_nil

    delete "/months/2026-05/payments/#{fee.id}/document_exception", params: {
      screen: "matches", bank_account_id: statement.bank_account_id
    }
    expect(response).to redirect_to("/months/2026-05/matches?bank_account_id=#{statement.bank_account_id}")
    expect(fee.reload.missing_document?).to eq(true)
  end

  it "GET matches closed is read-only without stamp" do
    _account, organization, month, statement = signed_month
    ExtraExceptionKind.create_for(organization: organization, name: "Doação", justification: "Isento de documento de suporte.")
    payment = plant_payment(statement, 22000)
    payment.mark_document_exception("bank_fee")
    month.update!(closed: true)

    get "/months/2026-05/matches"

    expect(response).to have_http_status(:ok)
    expect(page_doc(response.body).at_css("h1").text.strip).to eq("maio de 2026")
    expect(page_doc(response.body).css("a").find { |node| node.text.strip == "Voltar ao mês" }).to be_present
    expect(page_doc(response.body).at_css('input[type="checkbox"]')).to be_nil
    expect(response.body).not_to include("Confirmar casamento")
    expect(response.body).not_to include("Marcar tarifa")
    expect(response.body).not_to include("Marcar honorário")
    expect(response.body).not_to include("Doação")
    expect(page_doc(response.body).at_css('[aria-label="Desmarcar exceção"]')).to be_nil
    expect(page_doc(response.body).at_css('[aria-label="Desfazer casamento"]')).to be_nil
    expect(page_doc(response.body).at_css('[data-stamp="closed"]')).to be_nil
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
