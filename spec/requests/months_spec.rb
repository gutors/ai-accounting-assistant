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
    org_b = Organization.create!(name: "B")
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
    org_b = Organization.create!(name: "B")
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
    org_b = Organization.create!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :submitter)
    plant_month(org_b)
    sign_in_as(account, organization: org_b)

    get "/months/2026-05"

    expect(response).to have_http_status(:not_found)
  end

  it "coordinator focus GET /months/2026-05 responds 200 for mixed Access" do
    account, org_a = plant_coordinator(email: "mixed@example.com", organization_name: "A")
    org_b = Organization.create!(name: "B")
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
    marked_row = response.body.scan(%r{<li class="mb-2">.*?</li>}m).find { |li| li.include?("R$ 220,00") }
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
    org_b = Organization.create!(name: "B")
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

    rows = pagamentos_html(response.body).scan(%r{<li class="mb-2">.*?</li>}m)
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
end
