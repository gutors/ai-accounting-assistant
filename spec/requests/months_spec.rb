require "rails_helper"

RSpec.describe "Months", type: :request do
  it "unauthenticated GET /months/2026-05 responds 302 to /login" do
    get "/months/2026-05"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "GET /months/2026-05 without focus responds 302 to /login" do
    account, organization = plant_coordinator(email: "coord@example.com")
    other = Account.create!(email: "other@example.com", google_uid: "uid-other")
    Access.create!(account: other, organization: organization, kind: :coordinator)
    sign_in_as(account, organization: organization)
    Access.where(account: account).delete_all

    get "/months/2026-05"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "POST /months 2026-05 persists Month and redirects" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    post "/months", params: { year_month: "2026-05" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    expect(organization.months.where(year_month: "2026-05").count).to eq(1)
    follow_redirect!
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_node(response.body).text).to include("Pronto.")
  end

  it "POST /months 2026-05 a second time does not duplicate" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }

    post "/months", params: { year_month: "2026-05" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    expect(organization.months.where(year_month: "2026-05").count).to eq(1)
  end

  it "GET /months/2026-05 responds 200 with pt-BR and 2026-05" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }

    get "/months/2026-05"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('lang="pt-BR"')
    expect(response.body).to include("2026-05")
  end

  it "GET /months/2026-05 with zero active accounts includes Nenhuma conta bancaria ativa" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }

    get "/months/2026-05"

    expect(response.body).to include("Nenhuma conta bancária ativa")
  end

  it "GET /months/2026-05 includes active account name and Falta" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    post "/months", params: { year_month: "2026-05" }

    get "/months/2026-05"

    expect(response.body).to include("Conta Principal")
    expect(response.body).to include("Falta")
  end

  it "GET /months/2026-05 includes coordinates on the account card" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001", coordinates: "ag 1234")
    post "/months", params: { year_month: "2026-05" }

    get "/months/2026-05"

    expect(response.body).to include("ag 1234")
  end

  it "POST /months empty year_month returns 422 Informe um mes valido" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    expect do
      post "/months", params: { year_month: "" }
    end.not_to change(Month, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Informe um mês válido")
  end

  it "POST /months 2026-13 returns 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    expect do
      post "/months", params: { year_month: "2026-13" }
    end.not_to change(Month, :count)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "GET /months/2026-13 responds 404" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/months/2026-13"

    expect(response).to have_http_status(:not_found)
  end

  it "GET /months/2026-04 when never opened responds 404" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/months/2026-04"

    expect(response).to have_http_status(:not_found)
  end

  it "unauthenticated POST /months responds 302 to /login" do
    expect do
      post "/months", params: { year_month: "2026-05" }
    end.not_to change(Month, :count)

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "month page does not include another organization bank account names" do
    account, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    BankAccount.create_for(organization: org_a, name: "Conta Alfa", compe: "001")
    BankAccount.create_for(organization: org_b, name: "Conta Beta", compe: "001")
    sign_in_as(account, organization: org_a)
    post "/months", params: { year_month: "2026-05" }

    get "/months/2026-05"

    expect(response.body).to include("Conta Alfa")
    expect(response.body).not_to include("Conta Beta")
  end

  it "DELETE /months/2026-05 returns 404 and keeps the Month" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }

    delete "/months/2026-05"

    expect(response).to have_http_status(:not_found)
    expect(organization.months.where(year_month: "2026-05").count).to eq(1)
  end

  it "GET /months/2026-05 unmatched payment includes Documento faltante" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    _month, statement = plant_month(organization)
    plant_payment(statement, 22000)

    get "/months/2026-05"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Documento faltante")
    expect(response.body).to include("R$ 220,00")
  end

  it "GET /months/2026-05 with zero Payments does not include Documento faltante" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }

    get "/months/2026-05"

    expect(response.body).not_to include("Documento faltante")
  end

  it "GET /months/2026-05 includes Documentos sem casamento" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }

    get "/months/2026-05"

    expect(response.body).to include("Documentos sem casamento")
  end

  it "GET /months/2026-05 with no unmatched documents includes Nenhum documento sem casamento" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }

    get "/months/2026-05"

    expect(response.body).to include("Nenhum documento sem casamento")
  end

  it "GET /months/2026-05 pool includes unmatched Padaria Central" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization)
    plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    get "/months/2026-05"

    expect(pool_html(response.body)).to include("Padaria Central")
  end

  it "month unmatched pool does not include another organization payee" do
    account, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    plant_recibo(org_b, account, payee: "Only Org B", amount: "155,00")
    sign_in_as(account, organization: org_a)
    plant_month(org_a)

    get "/months/2026-05"

    expect(response.body).not_to include("Only Org B")
  end

  it "GET /months/2026-05 Recebimentos does not include Documento faltante" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    _month, statement = plant_month(organization)
    plant_inflow(statement, 6300)
    plant_payment(statement, 22000)

    get "/months/2026-05"

    expect(recebimentos_html(response.body)).not_to include("Documento faltante")
    expect(recebimentos_html(response.body)).to include("R$ 63,00")
  end

  it "GET /months/2026-05 with every payment resolved omits Documento faltante" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, statement = plant_month(organization)
    matched = plant_payment(statement, 22000)
    excepted = plant_payment(statement, 10000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    Match.confirm(month: month, payments: [ matched ], supporting_documents: [ document ])
    excepted.mark_document_exception("bank_fee")

    get "/months/2026-05"

    expect(response.body).not_to include("Documento faltante")
  end

  it "submitter focus GET /months/2026-05 responds 404" do
    account, org_a = plant_coordinator(email: "mixed@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :submitter)
    plant_month(org_b)
    sign_in_as(account, organization: org_b)

    get "/months/2026-05"

    expect(response).to have_http_status(:not_found)
  end

  it "coordinator focus GET /months/2026-05 responds 200 for mixed Access" do
    account, org_a = plant_coordinator(email: "mixed@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :submitter)
    plant_month(org_a)
    sign_in_as(account, organization: org_a)

    get "/months/2026-05"

    expect(response).to have_http_status(:ok)
  end

  it "submitter GET /months/2026-05 responds 404 and omits PIX Isolado" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    _month, statement = plant_month(organization)
    plant_payment(statement, 15500, history: "PIX Isolado")
    sign_in_as(submitter, organization: organization)

    get "/months/2026-05"

    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include("PIX Isolado")
  end

  it "submitter POST /months persists no Month and responds 404" do
    account, organization = plant_submitter
    sign_in_as(account, organization: organization)

    expect do
      post "/months", params: { year_month: "2026-05" }
    end.not_to change(Month, :count)

    expect(response).to have_http_status(:not_found)
  end

  it "GET /months/2026-05 includes Doacao as a mark choice" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    _month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)

    get "/months/2026-05"

    expect(response.body).to include("Doação")
    expect(response.body).to include("name=\"extra_exception_kind_id\"")
    expect(response.body).to include("value=\"#{organization.extra_exception_kinds.find_by!(name: "Doação").id}\"")
    expect(response.body).to include("Documento faltante")
    expect(payment).to be_missing_document
  end

  it "GET /months/2026-05 deactivated Doacao is not offered and stays on the marked payment" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    _month, statement = plant_month(organization)
    marked = plant_payment(statement, 22000)
    plant_payment(statement, 10000)
    marked.mark_document_exception(extra_exception_kind_id: kind.id)
    kind.apply_active(false)

    get "/months/2026-05"

    expect(response.body).not_to include("name=\"extra_exception_kind_id\"")
    marked_row = rows_html(response.body, "payment").find { |li| li.include?("R$ 220,00") }
    status = marked_row.split("<form").first
    expect(status).to include("Doação")
    expect(status).not_to include("Documento faltante")
  end

  it "GET /months/2026-05 with every payment extra-excepted omits Documento faltante" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    _month, statement = plant_month(organization)
    plant_payment(statement, 22000).mark_document_exception(extra_exception_kind_id: kind.id)
    plant_payment(statement, 10000).mark_document_exception(extra_exception_kind_id: kind.id)

    get "/months/2026-05"

    expect(response.body).not_to include("Documento faltante")
  end

  it "GET /months/2026-05 does not include another organization extra exception kind" do
    account, org_a = plant_coordinator(email: "coord@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    ExtraExceptionKind.create_for(organization: org_b, name: "Só B Extra")
    sign_in_as(account, organization: org_a)
    _month, statement = plant_month(org_a)
    plant_payment(statement, 22000)

    get "/months/2026-05"

    expect(response.body).not_to include("Só B Extra")
  end

  it "GET closed month shows deactivated Doacao without Desmarcar excecao" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    payment.mark_document_exception(extra_exception_kind_id: kind.id)
    kind.apply_active(false)
    month.update!(closed: true)

    get "/months/2026-05"

    expect(response.body).to include("Doação")
    expect(response.body).not_to include("Documento faltante")
    expect(response.body).not_to include("Desmarcar exceção")
  end

  def signed_open_month
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, statement = plant_month(organization)
    [ account, organization, month, statement ]
  end

  it "GET 1:1 equal Padaria Central includes Sugestao and Documento faltante" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    expect(response).to have_http_status(:ok)
    status = payment_status_html(response.body, history: "Pix enviado — Padaria Central")
    expect(status).to include("Documento faltante")
    expect(status).to include("Sugestão")
    expect(status).to include("Padaria Central")
  end

  it "GET 1:1 equal leaves Payment unmatched and document without month" do
    account, organization, _month, statement = signed_open_month
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    expect(response).to have_http_status(:ok)
    payment.reload
    document.reload
    expect(payment.match_id).to be_nil
    expect(payment.document_exception_kind).to be_nil
    expect(payment.extra_exception_kind_id).to be_nil
    expect(document.month_id).to be_nil
    expect(document.match_id).to be_nil
  end

  it "GET missing-document payment with no unmatched document omits Sugestao" do
    _account, _organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado — Padaria Central")
    expect(status).to include("Documento faltante")
    expect(status).not_to include("Sugestão")
  end

  it "GET /months/2026-05 with zero Payments omits Sugestao" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization)
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    expect(response.body).not_to include("Sugestão")
  end

  it "Recebimentos section omits Sugestao and Sugestao de excecao" do
    account, organization, _month, statement = signed_open_month
    plant_inflow(statement, 10000, history: "Pix - Recebido Padaria Central")
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    section = recebimentos_html(response.body)
    expect(section).to include("Pix - Recebido Padaria Central")
    expect(section).not_to include("Sugestão")
    expect(section).not_to include("Sugestão de exceção")
  end

  it "GET recibo 1:1 includes Sugestao and Padaria Central" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado — Padaria Central")
    expect(status).to include("Sugestão")
    expect(status).to include("Padaria Central")
    expect(document.kind).to eq("recibo")
  end

  it "GET nota_fiscal with XML 1:1 includes Sugestao and Padaria Central" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    document = plant_nota(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado — Padaria Central")
    expect(status).to include("Sugestão")
    expect(status).to include("Padaria Central")
    expect(document.kind).to eq("nota_fiscal")
    expect(document.xml).to be_attached
  end

  it "unmatched pool still includes Padaria Central while Sugestao shows" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado — Padaria Central")
    expect(status).to include("Sugestão")
    expect(status).to include("Padaria Central")
    expect(pool_html(response.body)).to include("Padaria Central")
  end

  it "GET after later document insert includes Sugestao" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    get "/months/2026-05"
    expect(payment_status_html(response.body, history: "Pix enviado — Padaria Central")).not_to include("Sugestão")

    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado — Padaria Central")
    expect(status).to include("Sugestão")
    expect(status).to include("Padaria Central")
  end

  it "GET value tie name hit assigns Padaria not Mercado" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    plant_payment(statement, 22000, history: "Pix enviado — Mercado Silva")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    padaria = payment_status_html(response.body, history: "Pix enviado — Padaria Central")
    mercado = payment_status_html(response.body, history: "Pix enviado — Mercado Silva")
    expect(padaria).to include("Sugestão")
    expect(padaria).to include("Padaria Central")
    expect(mercado).not_to include("Sugestão")
  end

  it "GET two name-hit equals assigns lower-id payment only" do
    account, organization, _month, statement = signed_open_month
    first = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    second = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    expect(first.id).to be < second.id

    get "/months/2026-05"

    rows = rows_html(response.body, "payment")
    suggested = rows.select { |row| row.split("<form").first.include?("Sugestão") }
    expect(suggested.size).to eq(1)
    expect(suggested.first).to include("value=\"#{first.id}\"")
    expect(suggested.first).not_to include("value=\"#{second.id}\"")
  end

  it "GET two equal docs name hit assigns Padaria Central not Mercado Silva" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    plant_recibo(organization, account, payee: "Mercado Silva", amount: "220,00")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado — Padaria Central")
    expect(status).to include("Sugestão")
    expect(status).to include("Padaria Central")
    expect(status).not_to include("Mercado Silva")
  end

  it "GET two equal docs no name hit assigns lower-id Padaria Norte" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix")
    norte = plant_recibo(organization, account, payee: "Padaria Norte", amount: "220,00")
    sul = plant_recibo(organization, account, payee: "Padaria Sul", amount: "220,00")
    expect(norte.id).to be < sul.id

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix")
    expect(status).to include("Sugestão")
    expect(status).to include("Padaria Norte")
    expect(status).not_to include("Padaria Sul")
  end

  it "GET cross-month name hit assigns May not June" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    _june, june_statement = plant_month(organization, year_month: "2026-06")
    plant_payment(june_statement, 22000, history: "Pix enviado — Mercado Silva")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"
    expect(payment_status_html(response.body, history: "Pix enviado — Padaria Central")).to include("Sugestão")

    get "/months/2026-06"
    expect(payment_status_html(response.body, history: "Pix enviado — Mercado Silva")).not_to include("Sugestão")
  end

  it "GET cross-month no name hit assigns lower-id payment month" do
    account, organization, _month, statement = signed_open_month
    may = plant_payment(statement, 22000, history: "Pix")
    _june, june_statement = plant_month(organization, year_month: "2026-06")
    june = plant_payment(june_statement, 22000, history: "Pix")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    lower = [ may, june ].min_by(&:id)
    other = [ may, june ].find { |payment| payment.id != lower.id }
    lower_month = lower.bank_statement.month.year_month
    other_month = other.bank_statement.month.year_month

    get "/months/#{lower_month}"
    expect(payment_status_html(response.body, history: "Pix")).to include("Sugestão")

    get "/months/#{other_month}"
    expect(payment_status_html(response.body, history: "Pix")).not_to include("Sugestão")
  end

  it "GET document_on before occurred_on still includes Sugestao" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central", occurred_on: Date.new(2026, 5, 20))
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00", date: "2026-04-30")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado — Padaria Central")
    expect(status).to include("Sugestão")
    expect(status).to include("Padaria Central")
  end

  it "GET equal with no name hit still includes Sugestao" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix enviado — Outro")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado — Outro")
    expect(status).to include("Sugestão")
    expect(status).to include("Padaria Central")
  end

  it "GET accent-fold name hit assigns Jose Silva not Mercado" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix enviado — JOSE SILVA")
    plant_payment(statement, 22000, history: "Pix enviado — Mercado Silva")
    plant_recibo(organization, account, payee: "José Silva", amount: "220,00")

    get "/months/2026-05"

    jose = payment_status_html(response.body, history: "Pix enviado — JOSE SILVA")
    mercado = payment_status_html(response.body, history: "Pix enviado — Mercado Silva")
    expect(jose).to include("Sugestão")
    expect(jose).to include("José Silva")
    expect(mercado).not_to include("Sugestão")
  end

  it "GET equal beats greater even when greater has name hit" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix enviado — Mercado Silva")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    plant_recibo(organization, account, payee: "Mercado Silva", amount: "250,00")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado — Mercado Silva")
    expect(status).to include("Sugestão")
    copy = status[status.index("Sugestão")..]
    expect(copy).to include("Padaria Central")
    expect(copy).not_to include("Mercado Silva")
  end

  it "GET greater beats lesser" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix enviado — Pagamento")
    plant_recibo(organization, account, payee: "Padaria Grande", amount: "250,00")
    plant_recibo(organization, account, payee: "Padaria Pequena", amount: "200,00")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado — Pagamento")
    expect(status).to include("Sugestão")
    expect(status).to include("Padaria Grande")
    expect(status).not_to include("Padaria Pequena")
  end

  it "GET lesser 1:1 includes Sugestao and Padaria Central" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix enviado — Pagamento")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "200,00")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado — Pagamento")
    expect(status).to include("Sugestão")
    expect(status).to include("Padaria Central")
  end

  it "GET format-2 both payments include Sugestao and Padaria Central" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 10000, history: "Pix enviado — Dez")
    plant_payment(statement, 12000, history: "Pix enviado — Doze")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    ten = payment_status_html(response.body, history: "Pix enviado — Dez")
    twelve = payment_status_html(response.body, history: "Pix enviado — Doze")
    expect(ten).to include("Sugestão")
    expect(ten).to include("Padaria Central")
    expect(twelve).to include("Sugestão")
    expect(twelve).to include("Padaria Central")
  end

  it "GET equal beats format-2" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix enviado — Igual")
    plant_payment(statement, 10000, history: "Pix enviado — Dez")
    plant_payment(statement, 12000, history: "Pix enviado — Doze")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    expect(payment_status_html(response.body, history: "Pix enviado — Igual")).to include("Sugestão")
    expect(payment_status_html(response.body, history: "Pix enviado — Igual")).to include("Padaria Central")
    expect(payment_status_html(response.body, history: "Pix enviado — Dez")).not_to include("Sugestão")
  end

  it "GET format-2 name hit beats format-2 no name hit" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 10000, history: "Pix enviado — Padaria Central")
    plant_payment(statement, 12000, history: "Pix enviado — Padaria Central 2")
    plant_payment(statement, 10000, history: "Outro Dez")
    plant_payment(statement, 12000, history: "Outro Doze")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    expect(payment_status_html(response.body, history: "Pix enviado — Padaria Central")).to include("Sugestão")
    expect(payment_status_html(response.body, history: "Pix enviado — Padaria Central 2")).to include("Sugestão")
    expect(payment_status_html(response.body, history: "Outro Dez")).not_to include("Sugestão")
    expect(payment_status_html(response.body, history: "Outro Doze")).not_to include("Sugestão")
  end

  it "GET three payments does not group all three as one suggestion" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 7000, history: "Pix enviado — A")
    plant_payment(statement, 7000, history: "Pix enviado — B")
    plant_payment(statement, 8000, history: "Pix enviado — C")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    suggested = [ "Pix enviado — A", "Pix enviado — B", "Pix enviado — C" ].count do |history|
      payment_status_html(response.body, history: history).include?("Sugestão")
    end
    expect(suggested).to be < 3
  end

  def cover_docs(organization, account, amount:, documents:)
    Justification.declare(
      organization: organization,
      account: account,
      amount: amount,
      supporting_document_ids: documents.map(&:id)
    )
  end

  it "GET justification equal includes both payees and Documento faltante" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 20000, history: "Pix enviado — Gasto")
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "45,00")
    cover_docs(organization, account, amount: "200,00", documents: [ padaria, mercado ])

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado — Gasto")
    expect(status).to include("Sugestão")
    expect(status).to include("Padaria Central")
    expect(status).to include("Mercado Silva")
    expect(status).to include("Documento faltante")
  end

  it "GET justification member is not assigned as an individual" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 20000, history: "Pix enviado — Igual")
    plant_payment(statement, 15500, history: "Pix enviado — Membro")
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "45,00")
    cover_docs(organization, account, amount: "200,00", documents: [ padaria, mercado ])

    get "/months/2026-05"

    member = payment_status_html(response.body, history: "Pix enviado — Membro")
    expect(member).not_to include("Sugestão")
  end

  it "GET does not format-2 a multi-document justification" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 10000, history: "Pix enviado — A")
    plant_payment(statement, 10000, history: "Pix enviado — B")
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "45,00")
    cover_docs(organization, account, amount: "200,00", documents: [ padaria, mercado ])

    get "/months/2026-05"

    suggested = [ "Pix enviado — A", "Pix enviado — B" ].count do |history|
      payment_status_html(response.body, history: history).include?("Sugestão")
    end
    expect(suggested).to be < 2
  end

  it "GET justification amount_cents 18000 equal includes both payees" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 18000, history: "Pix enviado — Gasto")
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "45,00")
    cover_docs(organization, account, amount: "180,00", documents: [ padaria, mercado ])

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado — Gasto")
    expect(status).to include("Sugestão")
    expect(status).to include("Padaria Central")
    expect(status).to include("Mercado Silva")
  end

  it "GET justification 22000 with members 20000 includes Sugestao" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix enviado — Gasto")
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "45,00")
    cover_docs(organization, account, amount: "220,00", documents: [ padaria, mercado ])

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado — Gasto")
    expect(status).to include("Sugestão")
    expect(status).to include("Padaria Central")
    expect(status).to include("Mercado Silva")
  end

  def set_pix(organization, key)
    organization.update!(accountant_presentation_name: "Ana Contadora", accountant_pix_key: key)
  end

  it "GET PIX chave-pix includes Sugestao de excecao and Documento faltante" do
    _account, organization, _month, statement = signed_open_month
    set_pix(organization, "chave-pix")
    plant_payment(statement, 22000, history: "Pix enviado chave-pix")

    get "/months/2026-05"

    expect(response).to have_http_status(:ok)
    status = payment_status_html(response.body, history: "Pix enviado chave-pix")
    expect(status).to include("Sugestão de exceção")
    expect(status).to include("Documento faltante")
    expect(status).not_to include("Honorário do contador")
  end

  it "GET exception suggestion leaves document_exception_kind nil" do
    _account, organization, _month, statement = signed_open_month
    set_pix(organization, "chave-pix")
    payment = plant_payment(statement, 22000, history: "Pix enviado chave-pix")

    get "/months/2026-05"

    expect(response).to have_http_status(:ok)
    expect(payment.reload.document_exception_kind).to be_nil
  end

  it "GET tax id digits in history includes Sugestao de excecao" do
    _account, organization, _month, statement = signed_open_month
    organization.update!(accountant_presentation_name: "Ana Contadora", accountant_tax_id: "39053344705")
    plant_payment(statement, 22000, history: "Pix 390.533.447-05")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix 390.533.447-05")
    expect(status).to include("Sugestão de exceção")
  end

  it "GET PIX email case-insensitive includes Sugestao de excecao" do
    _account, organization, _month, statement = signed_open_month
    set_pix(organization, "ana@example.com")
    plant_payment(statement, 22000, history: "Pix Ana@Example.com")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix Ana@Example.com")
    expect(status).to include("Sugestão de exceção")
  end

  it "GET PIX phone digits includes Sugestao de excecao" do
    _account, organization, _month, statement = signed_open_month
    set_pix(organization, "51999999999")
    plant_payment(statement, 22000, history: "Pix +55 51 99999-9999")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix +55 51 99999-9999")
    expect(status).to include("Sugestão de exceção")
  end

  it "GET PIX uuid digits includes Sugestao de excecao" do
    _account, organization, _month, statement = signed_open_month
    set_pix(organization, "f9c8d7e6-1234-4abc-9def-0123456789ab")
    plant_payment(statement, 22000, history: "Pix F9C8D7E6-1234-4ABC-9DEF-0123456789AB")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix F9C8D7E6-1234-4ABC-9DEF-0123456789AB")
    expect(status).to include("Sugestão de exceção")
  end

  it "GET two PIX hits both include Sugestao de excecao" do
    _account, organization, _month, statement = signed_open_month
    set_pix(organization, "chave-pix")
    plant_payment(statement, 22000, history: "Pix enviado chave-pix A")
    plant_payment(statement, 15000, history: "Pix enviado chave-pix B")

    get "/months/2026-05"

    expect(payment_status_html(response.body, history: "Pix enviado chave-pix A")).to include("Sugestão de exceção")
    expect(payment_status_html(response.body, history: "Pix enviado chave-pix B")).to include("Sugestão de exceção")
  end

  it "GET presentation name does not include Sugestao de excecao" do
    _account, organization, _month, statement = signed_open_month
    organization.update!(accountant_presentation_name: "Ana Contadora")
    plant_payment(statement, 22000, history: "Pix Ana Contadora")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix Ana Contadora")
    expect(status).not_to include("Sugestão de exceção")
  end

  it "GET razao social does not include Sugestao de excecao" do
    _account, organization, _month, statement = signed_open_month
    organization.update!(accountant_presentation_name: "Ana", accountant_legal_name: "Ana Contabilidade LTDA")
    plant_payment(statement, 22000, history: "Pix Ana Contabilidade LTDA")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix Ana Contabilidade LTDA")
    expect(status).not_to include("Sugestão de exceção")
  end

  it "GET empty PIX and tax id omits Sugestao de excecao" do
    _account, _organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix 390.533.447-05")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix 390.533.447-05")
    expect(status).not_to include("Sugestão de exceção")
  end

  it "GET match suggestion suppresses Sugestao de excecao" do
    account, organization, _month, statement = signed_open_month
    set_pix(organization, "chave-pix")
    plant_payment(statement, 22000, history: "Pix enviado chave-pix — Padaria Central")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado chave-pix — Padaria Central")
    expect(status).to include("Sugestão")
    expect(status).to include("Padaria Central")
    expect(status).not_to include("Sugestão de exceção")
  end

  it "GET lesser match suggestion suppresses Sugestao de excecao" do
    account, organization, _month, statement = signed_open_month
    set_pix(organization, "chave-pix")
    plant_payment(statement, 50000, history: "Pix enviado chave-pix")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "200,00")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado chave-pix")
    expect(status).to include("Sugestão")
    expect(status).not_to include("Sugestão de exceção")
  end

  it "GET tarifa history omits Sugestao de excecao" do
    _account, _organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Tarifa Pacote de Serviços")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Tarifa Pacote de Serviços")
    expect(status).not_to include("Sugestão de exceção")
  end

  it "GET extra exception kind is not Sugestao de excecao" do
    _account, organization, _month, statement = signed_open_month
    ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    plant_payment(statement, 22000, history: "Pix enviado")

    get "/months/2026-05"

    expect(response.body).to include("Doação")
    expect(payment_status_html(response.body, history: "Pix enviado")).not_to include("Sugestão de exceção")
  end

  it "GET org A omits Sugestao of org B payee" do
    account, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    sign_in_as(account, organization: org_a)
    _month, statement = plant_month(org_a)
    plant_payment(statement, 22000, history: "Pix enviado — Mesmo valor")
    b_account = Account.create!(email: "b@example.com", google_uid: "uid-b")
    Access.create!(account: b_account, organization: org_b, kind: :coordinator)
    plant_recibo(org_b, b_account, payee: "Padaria Beta Isolada", amount: "220,00")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado — Mesmo valor")
    expect(status).not_to include("Sugestão")
    expect(response.body).not_to include("Padaria Beta Isolada")
  end

  it "GET closed month omits Sugestao and Sugestao de excecao" do
    account, organization, month, statement = signed_open_month
    set_pix(organization, "chave-pix")
    plant_payment(statement, 22000, history: "Pix enviado chave-pix — Padaria Central")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    month.update!(closed: true)

    get "/months/2026-05"

    expect(response.body).not_to include("Sugestão")
    expect(response.body).not_to include("Sugestão de exceção")
  end

  it "submitter GET omits PIX Isolado Sugestao and Padaria Central" do
    coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    _month, statement = plant_month(organization)
    plant_payment(statement, 22000, history: "PIX Isolado")
    plant_recibo(organization, coord, payee: "Padaria Central", amount: "220,00")
    sign_in_as(submitter, organization: organization)

    get "/months/2026-05"

    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include("PIX Isolado")
    expect(response.body).not_to include("Sugestão")
    expect(response.body).not_to include("Padaria Central")
  end

  it "coordinator GET includes Sugestao of submitter document" do
    coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    _month, statement = plant_month(organization)
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    sign_in_as(submitter, organization: organization)
    post "/supporting_documents", params: {
      kind: "recibo", amount: "220,00", date: "2026-05-11", payee: "Padaria Central", photo: photo_jpg
    }

    sign_in_as(coord, organization: organization)
    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado — Padaria Central")
    expect(status).to include("Sugestão")
    expect(status).to include("Padaria Central")
  end

  it "GET 1:1 form selects payment id and document id" do
    account, organization, _month, statement = signed_open_month
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    form = payment_row_html(response.body, history: "Pix enviado — Padaria Central")
    expect(selected_named_values(form, "payment_ids[]")).to include(payment.id.to_s)
    expect(selected_named_values(form, "supporting_document_ids[]")).to include(document.id.to_s)
  end

  it "GET 1:1 form does not select Mercado Silva" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "220,00")

    get "/months/2026-05"

    form = payment_row_html(response.body, history: "Pix enviado — Padaria Central")
    expect(selected_named_values(form, "supporting_document_ids[]")).not_to include(mercado.id.to_s)
  end

  it "GET format-2 N:1 form selects both payment ids and the document id" do
    account, organization, _month, statement = signed_open_month
    ten = plant_payment(statement, 10000, history: "Pix enviado — Dez")
    twelve = plant_payment(statement, 12000, history: "Pix enviado — Doze")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    form = n1_match_form_html(response.body)
    expect(form).to include("/months/2026-05/matches")
    expect(selected_named_values(form, "payment_ids[]")).to include(ten.id.to_s, twelve.id.to_s)
    expect(selected_named_values(form, "supporting_document_ids[]")).to include(document.id.to_s)
  end

  it "GET two format-2 N:1 form selects the pair with lowest payment id" do
    account, organization, _month, statement = signed_open_month
    ten = plant_payment(statement, 10000, history: "Pix enviado — Dez")
    twelve = plant_payment(statement, 12000, history: "Pix enviado — Doze")
    fourteen = plant_payment(statement, 14000, history: "Pix enviado — Catorze")
    sixteen = plant_payment(statement, 16000, history: "Pix enviado — Dezesseis")
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "300,00")

    get "/months/2026-05"

    form = n1_match_form_html(response.body)
    expect(form).to include("/months/2026-05/matches")
    selected_payments = selected_named_values(form, "payment_ids[]")
    selected_documents = selected_named_values(form, "supporting_document_ids[]")
    expect(ten.id).to be < fourteen.id
    expect(selected_payments).to include(ten.id.to_s, twelve.id.to_s)
    expect(selected_payments).not_to include(fourteen.id.to_s, sixteen.id.to_s)
    expect(selected_documents).to include(padaria.id.to_s)
    expect(selected_documents).not_to include(mercado.id.to_s)
  end

  it "GET justification form selects both member document ids" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 20000, history: "Pix enviado — Gasto")
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "45,00")
    cover_docs(organization, account, amount: "200,00", documents: [ padaria, mercado ])

    get "/months/2026-05"

    form = payment_row_html(response.body, history: "Pix enviado — Gasto")
    selected_documents = selected_named_values(form, "supporting_document_ids[]")
    expect(selected_documents).to include(padaria.id.to_s, mercado.id.to_s)
  end

  it "GET format-2 1:1 form does not select Padaria Central" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 10000, history: "Pix enviado — Dez")
    plant_payment(statement, 12000, history: "Pix enviado — Doze")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    ten_form = payment_row_html(response.body, history: "Pix enviado — Dez")
    twelve_form = payment_row_html(response.body, history: "Pix enviado — Doze")
    expect(selected_named_values(ten_form, "supporting_document_ids[]")).not_to include(document.id.to_s)
    expect(selected_named_values(twelve_form, "supporting_document_ids[]")).not_to include(document.id.to_s)
  end

  it "POST format-2 1:1 form as shown returns 422 and leaves both unmatched" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 10000, history: "Pix enviado — Dez")
    plant_payment(statement, 12000, history: "Pix enviado — Doze")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"
    form = payment_row_html(response.body, history: "Pix enviado — Dez")
    post "/months/2026-05/matches", params: {
      payment_ids: selected_named_values(form, "payment_ids[]"),
      supporting_document_ids: selected_named_values(form, "supporting_document_ids[]")
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Selecione ao menos um documento")
    expect(Match.count).to eq(0)

    get "/months/2026-05"
    ten_status = payment_status_html(response.body, history: "Pix enviado — Dez")
    twelve_status = payment_status_html(response.body, history: "Pix enviado — Doze")
    expect(ten_status).to include("Documento faltante")
    expect(ten_status).to include("Sugestão")
    expect(twelve_status).to include("Documento faltante")
    expect(twelve_status).to include("Sugestão")
  end

  it "GET 1:1 form selects Padaria Central when suggestion has one payment" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    form = payment_row_html(response.body, history: "Pix enviado — Padaria Central")
    expect(selected_named_values(form, "supporting_document_ids[]")).to include(document.id.to_s)
  end

  it "GET justification form selects both members when suggestion has one payment" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 20000, history: "Pix enviado — Gasto")
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "45,00")
    cover_docs(organization, account, amount: "200,00", documents: [ padaria, mercado ])

    get "/months/2026-05"

    form = payment_row_html(response.body, history: "Pix enviado — Gasto")
    selected_documents = selected_named_values(form, "supporting_document_ids[]")
    expect(selected_documents).to include(padaria.id.to_s, mercado.id.to_s)
  end

  it "GET open month lists Padaria close checkbox and Fechar turbo confirm" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")

    get "/months/2026-05"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Documentos sem casamento")
    expect(pool_html(response.body)).to include("Padaria Central")
    expect(pool_close_document_ids(response.body)).to include(document.id)
    expect(response.body).to include('data-turbo-confirm="Fechar o mês para envio?"')
  end

  it "GET closed month with unmatched Padaria includes Restaurar pasta and omits Mercado Silva" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ready_to_close!(organization)
    plant_month(organization)
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    post "/months/2026-05/close", params: { supporting_document_ids: [ padaria.id ] }
    plant_recibo(organization, account, payee: "Mercado Silva", amount: "45,00")

    get "/months/2026-05"

    expect(response.body).to include("Mês fechado")
    expect(response.body).to include("Restaurar pasta")
    expect(response.body).to include("Reabrir")
    expect(pool_html(response.body)).to include("Padaria Central")
    expect(response.body).not_to include("Fechar para envio")
    expect(pool_html(response.body)).not_to include("Mercado Silva")
    expect(response.body).to include('data-turbo-confirm="Restaurar a pasta do mês no arquivo do pacote?"')
    expect(response.body).to include('data-turbo-confirm="Reabrir o mês?"')
  end

  it "GET June omits May unmatched-in-package Padaria from the pool" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ready_to_close!(organization)
    plant_month(organization, year_month: "2026-05")
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    post "/months/2026-05/close", params: { supporting_document_ids: [ padaria.id ] }
    plant_month(organization, year_month: "2026-06")

    get "/months/2026-06"

    expect(pool_html(response.body)).not_to include("Padaria Central")
    expect(page_close_document_ids(response.body)).not_to include(padaria.id)
  end

  it "GET June does not suggest closed May unmatched-in-package Padaria" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ready_to_close!(organization)
    plant_month(organization, year_month: "2026-05")
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    post "/months/2026-05/close", params: { supporting_document_ids: [ padaria.id ] }
    _june, june_statement = plant_month(organization, year_month: "2026-06")
    plant_payment(june_statement, 22000, history: "Pix enviado — Padaria Central")

    get "/months/2026-06"

    status = payment_status_html(response.body, history: "Pix enviado — Padaria Central")
    expect(status).to include("Documento faltante")
    expect(status).not_to include("Sugestão")
  end

  it "GET reopened May suggests unmatched-in-package Padaria" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ready_to_close!(organization)
    _month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    payment.mark_document_exception("bank_fee")
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    post "/months/2026-05/close", params: { supporting_document_ids: [ padaria.id ] }
    post "/months/2026-05/reopen"
    delete "/months/2026-05/payments/#{payment.id}/document_exception"

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado — Padaria Central")
    expect(status).to include("Documento faltante")
    expect(status).to include("Sugestão")
    expect(status).to include("Padaria Central")
  end

  it "GET June does not suggest a justification that includes May unmatched Padaria" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ready_to_close!(organization)
    plant_month(organization, year_month: "2026-05")
    padaria = plant_recibo(organization, account, payee: "Padaria Central", amount: "155,00")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "45,00")
    Justification.declare(
      organization: organization,
      account: account,
      amount: "200,00",
      supporting_document_ids: [ padaria.id, mercado.id ]
    )
    post "/months/2026-05/close", params: { supporting_document_ids: [ padaria.id ] }
    _june, june_statement = plant_month(organization, year_month: "2026-06")
    plant_payment(june_statement, 20000, history: "Pix enviado — Gasto")

    get "/months/2026-06"

    status = payment_status_html(response.body, history: "Pix enviado — Gasto")
    expect(status).not_to match(/Sugestão[\s\S]*Padaria Central/)
  end

  # Ledger arrangement (visual-identity C17–C25, C29–C33, C35, C36)

  def resolver_details(row)
    details = row.css("details").select { |node| node.at_css("summary")&.text&.strip == "Resolver" }
    expect(details.size).to eq(1)
    details.first
  end

  it "month title is maio de 2026 with 2026-05 under it" do
    signed_open_month

    get "/months/2026-05"

    expect(response).to have_http_status(:ok)
    expect(page_doc(response.body).at_css("h1").text).to include("maio de 2026")
    expect(response.body).to include("2026-05")
  end

  it "summary says 2 pagamentos com documento faltante" do
    _account, _organization, _month, statement = signed_open_month
    plant_payment(statement, 22000)
    plant_payment(statement, 10000)

    get "/months/2026-05"

    expect(response.body).to include("2 pagamentos com documento faltante")
  end

  it "summary says 1 pagamento com documento faltante" do
    _account, _organization, _month, statement = signed_open_month
    plant_payment(statement, 22000)

    get "/months/2026-05"

    expect(response.body).to include("1 pagamento com documento faltante")
  end

  it "summary says Nenhum documento faltante and no row says Documento faltante" do
    _account, _organization, _month, statement = signed_open_month
    plant_payment(statement, 15500, history: "Tarifa").mark_document_exception("bank_fee")

    get "/months/2026-05"

    expect(response.body).to include("Nenhum documento faltante")
    expect(response.body).not_to include("Documento faltante")
  end

  it "summary says Falta o extrato de 1 conta ativa" do
    _account, organization, _month, _statement = signed_open_month
    BankAccount.create_for(organization: organization, name: "Conta Alfa", compe: "033")

    get "/months/2026-05"

    expect(response.body).to include("Falta o extrato de 1 conta ativa")
  end

  it "summary says Falta o extrato de 2 contas ativas" do
    _account, organization, _month, _statement = signed_open_month
    BankAccount.create_for(organization: organization, name: "Conta Alfa", compe: "033")
    BankAccount.create_for(organization: organization, name: "Conta Beta", compe: "104")

    get "/months/2026-05"

    expect(response.body).to include("Falta o extrato de 2 contas ativas")
  end

  it "summary omits Falta o extrato when every active account has a statement" do
    _account, organization, _month, _statement = signed_open_month
    inactive = BankAccount.create_for(organization: organization, name: "Parada", compe: "033")
    inactive.apply_from(active: false)

    get "/months/2026-05"

    expect(response.body).not_to include("Falta o extrato")
  end

  it "payment row data-status is missing" do
    _account, _organization, _month, statement = signed_open_month
    payment = plant_payment(statement, 22000)

    get "/months/2026-05"

    expect(row(response.body, "payment", payment_id: payment.id, status: "missing")).not_to be_nil
  end

  it "payment row data-status is matched" do
    account, organization, month, statement = signed_open_month
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])

    get "/months/2026-05"

    expect(row(response.body, "payment", payment_id: payment.id, status: "matched")).not_to be_nil
  end

  it "inflow pool-document and bank-account rows carry data-row hooks" do
    account, organization, _month, statement = signed_open_month
    plant_inflow(statement, 6300)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    bank_account = statement.bank_account

    get "/months/2026-05"

    expect(rows(response.body, "inflow").size).to eq(1)
    expect(row(response.body, "pool-document", document_id: document.id)).not_to be_nil
    expect(row(response.body, "bank-account", bank_account_id: bank_account.id)).not_to be_nil
  end

  it "missing row folds its forms under Resolver after the status" do
    _account, _organization, _month, statement = signed_open_month
    payment = plant_payment(statement, 22000)

    get "/months/2026-05"

    payment_row = row(response.body, "payment", payment_id: payment.id)
    details = resolver_details(payment_row)
    forms = payment_row.css("form")
    expect(forms).not_to be_empty
    expect(forms.all? { |form| form.ancestors.include?(details) }).to eq(true)
    html = payment_row.to_html
    expect(html.index("Documento faltante")).to be < html.index("<details")
  end

  it "Resolver is open when a suggestion exists" do
    account, organization, _month, statement = signed_open_month
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    details = resolver_details(row(response.body, "payment", payment_id: payment.id))
    expect(details.has_attribute?("open")).to eq(true)
  end

  it "Resolver is open when an exception suggestion exists" do
    _account, organization, _month, statement = signed_open_month
    set_pix(organization, "chave-pix")
    payment = plant_payment(statement, 22000, history: "Pix enviado chave-pix")

    get "/months/2026-05"

    details = resolver_details(row(response.body, "payment", payment_id: payment.id))
    expect(details.has_attribute?("open")).to eq(true)
  end

  it "Resolver is closed when no suggestion exists" do
    _account, _organization, _month, statement = signed_open_month
    payment = plant_payment(statement, 22000)

    get "/months/2026-05"

    details = resolver_details(row(response.body, "payment", payment_id: payment.id))
    expect(details.has_attribute?("open")).to eq(false)
  end

  it "present statement folds the upload form under Substituir extrato" do
    _account, _organization, _month, statement = signed_open_month
    attach_statement_files(statement)

    get "/months/2026-05"

    account_row = row(response.body, "bank-account", bank_account_id: statement.bank_account_id)
    form = account_row.css("form").find { |node| node["action"] == "/months/2026-05/bank_statements" }
    expect(form).not_to be_nil
    details = form.ancestors("details").first
    expect(details).not_to be_nil
    expect(details.at_css("summary").text.strip).to eq("Substituir extrato")
  end

  it "absent statement shows the upload form inline" do
    _account, organization, _month, _statement = signed_open_month
    bank_account = BankAccount.create_for(organization: organization, name: "Conta Alfa", compe: "033")

    get "/months/2026-05"

    account_row = row(response.body, "bank-account", bank_account_id: bank_account.id)
    form = account_row.css("form").find { |node| node["action"] == "/months/2026-05/bank_statements" }
    expect(form).not_to be_nil
    expect(form.ancestors("details")).to be_empty
  end
end
