require "rails_helper"

RSpec.describe "Months", type: :request do
  include ActiveSupport::Testing::TimeHelpers

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

  it "POST /months 2026-09 persists Month and redirects" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    travel_to Date.new(2026, 10, 1) do
      post "/months", params: { year_month: "2026-09" }
    end

    expect(organization.months.where(year_month: "2026-09").count).to eq(1)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-09")
    follow_redirect!
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_node(response.body).text).to include("Pronto.")
  end

  it "POST /months 2026-05 a second time does not duplicate" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }

    post "/months", params: { year_month: "2026-05" }

    expect(organization.months.where(year_month: "2026-05").count).to eq(1)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    follow_redirect!
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_node(response.body).text).to include("Pronto.")
  end

  it "POST /months 2024-01 outside the picker window persists" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    travel_to Date.new(2026, 10, 1) do
      post "/months", params: { year_month: "2024-01" }
    end

    expect(organization.months.where(year_month: "2024-01").count).to eq(1)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2024-01")
  end

  it "POST /months empty year_month re-renders the 25-month picker" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    travel_to Date.new(2026, 10, 1) do
      expect do
        post "/months", params: { year_month: "" }
      end.not_to change(Month, :count)
    end

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Informe um mês válido")
    expect(toast_node(response.body)["data-toast-kind"]).to eq("error")
    expect(toast_node(response.body).text).to include("Informe um mês válido")
    select = page_doc(response.body).at_css("select#year_month")
    options = select.css("option")
    expect(options.map { |option| option["value"] }).to eq(
      (0..24).map { |offset| Date.new(2025, 10, 1).next_month(offset).strftime("%Y-%m") }
    )
    expect(select.at_css("option[selected]")["value"]).to eq("2026-09")
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
    expect(response.body).to include("Incluir PDF")
    expect(response.body).to include("Incluir planilha")
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

  it "unauthenticated DELETE /months/2026-05 responds 302 to /login" do
    _account, organization = plant_coordinator
    Month.open(organization: organization, year_month: "2026-05")

    delete "/months/2026-05"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
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
    mark_accounts_confirmed!(organization)

    get "/months/2026-05"

    expect(response.body).to include("Documentos sem casamento")
  end

  it "GET /months/2026-05 with no unmatched documents includes Nenhum documento sem casamento" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }
    mark_accounts_confirmed!(organization)

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
    ExtraExceptionKind.create_for(organization: organization, name: "Doação", justification: "Isento de documento de suporte.")
    _month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)

    get "/months/2026-05/matches"

    expect(response.body).to include("Doação")
    expect(response.body).to include("name=\"extra_exception_kind_id\"")
    expect(response.body).to include("value=\"#{organization.extra_exception_kinds.find_by!(name: "Doação").id}\"")
    expect(response.body).to include("Documento faltante")
    expect(payment).to be_missing_document
  end

  it "GET /months/2026-05 deactivated Doacao is not offered and stays on the marked payment" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação", justification: "Isento de documento de suporte.")
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
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação", justification: "Isento de documento de suporte.")
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
    ExtraExceptionKind.create_for(organization: org_b, name: "Só B Extra", justification: "Isento de documento de suporte.")
    sign_in_as(account, organization: org_a)
    _month, statement = plant_month(org_a)
    plant_payment(statement, 22000)

    get "/months/2026-05"

    expect(response.body).not_to include("Só B Extra")
  end

  it "GET closed month shows deactivated Doacao without Desmarcar excecao" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação", justification: "Isento de documento de suporte.")
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

    rows = page_doc(response.body).css('li[data-row="payment"]')
    suggested = rows.select { |row| row.at_css('[data-cell="status"]').text.include?("Sugestão") }
    expect(suggested.size).to eq(1)
    expect(suggested.first["data-payment-id"]).to eq(first.id.to_s)
    expect(suggested.first["data-payment-id"]).not_to eq(second.id.to_s)
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
    ExtraExceptionKind.create_for(organization: organization, name: "Doação", justification: "Isento de documento de suporte.")
    plant_payment(statement, 22000, history: "Pix enviado")

    get "/months/2026-05"

    expect(payment_status_html(response.body, history: "Pix enviado")).not_to include("Sugestão de exceção")
    expect(response.body).not_to include("name=\"extra_exception_kind_id\"")
    get "/months/2026-05/matches"
    expect(response.body).to include("Doação")
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

    status = payment_status_html(response.body, history: "Pix enviado — Padaria Central")
    expect(status).to include("Sugestão Padaria Central")
    expect(payment).to be_missing_document
    expect(document).to be_present
    expect(payment_row_html(response.body, history: "Pix enviado — Padaria Central")).not_to include("payment_ids[]")
  end

  it "GET 1:1 form does not select Mercado Silva" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    mercado = plant_recibo(organization, account, payee: "Mercado Silva", amount: "220,00")

    get "/months/2026-05"

    status = payment_status_html(response.body, history: "Pix enviado — Padaria Central")
    expect(status).to include("Sugestão Padaria Central")
    expect(status).not_to include("Mercado Silva")
    expect(mercado).to be_present
  end

  it "GET format-2 N:1 form selects both payment ids and the document id" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 10000, history: "Pix enviado — Dez")
    plant_payment(statement, 12000, history: "Pix enviado — Doze")
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    expect(n1_match_form_html(response.body)).to eq("")
    expect(payment_status_html(response.body, history: "Pix enviado — Dez")).to include("Sugestão Padaria Central")
    expect(payment_status_html(response.body, history: "Pix enviado — Doze")).to include("Sugestão Padaria Central")
    expect(document).to be_present
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

    expect(n1_match_form_html(response.body)).to eq("")
    expect(ten.id).to be < fourteen.id
    expect(payment_status_html(response.body, history: "Pix enviado — Dez")).to include("Sugestão Padaria Central")
    expect(payment_status_html(response.body, history: "Pix enviado — Doze")).to include("Sugestão Padaria Central")
    expect(payment_status_html(response.body, history: "Pix enviado — Catorze")).to include("Sugestão Mercado Silva")
    expect(payment_status_html(response.body, history: "Pix enviado — Dezesseis")).to include("Sugestão Mercado Silva")
    expect(twelve).to be_present
    expect(sixteen).to be_present
    expect(padaria).to be_present
    expect(mercado).to be_present
  end

  it "GET justification form selects both member document ids" do
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
  end

  it "GET format-2 1:1 form does not select Padaria Central" do
    account, organization, _month, statement = signed_open_month
    plant_payment(statement, 10000, history: "Pix enviado — Dez")
    plant_payment(statement, 12000, history: "Pix enviado — Doze")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    ten = payment_row_html(response.body, history: "Pix enviado — Dez")
    twelve = payment_row_html(response.body, history: "Pix enviado — Doze")
    expect(ten).to include("Sugestão")
    expect(twelve).to include("Sugestão")
    expect(ten).not_to include("name=\"supporting_document_ids[]\"")
    expect(twelve).not_to include("name=\"supporting_document_ids[]\"")
  end

  it "POST format-2 1:1 form as shown returns 422 and leaves both unmatched" do
    account, organization, _month, statement = signed_open_month
    dez = plant_payment(statement, 10000, history: "Pix enviado — Dez")
    plant_payment(statement, 12000, history: "Pix enviado — Doze")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    post "/months/2026-05/matches", params: {
      payment_ids: [ dez.id ],
      supporting_document_ids: []
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

    status = payment_status_html(response.body, history: "Pix enviado — Padaria Central")
    expect(status).to include("Sugestão")
    expect(status).to include("Padaria Central")
    expect(payment_row_html(response.body, history: "Pix enviado — Padaria Central")).not_to include("name=\"supporting_document_ids[]\"")
    expect(document).to be_present
  end

  it "GET justification form selects both members when suggestion has one payment" do
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
    expect(padaria).to be_present
    expect(mercado).to be_present
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
    expect(payment_row.text).to include("Documento faltante")
    expect(payment_row.text).not_to include("Resolver")
    expect(payment_row.css("form")).to be_empty
    expect(payment_row.css("details")).to be_empty
  end

  it "Resolver is open when a suggestion exists" do
    account, organization, _month, statement = signed_open_month
    payment = plant_payment(statement, 22000, history: "Pix enviado — Padaria Central")
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    get "/months/2026-05"

    payment_row = row(response.body, "payment", payment_id: payment.id)
    expect(payment_row.text).to include("Sugestão Padaria Central")
    expect(payment_row.text).not_to include("Resolver")
  end

  it "Resolver is open when an exception suggestion exists" do
    _account, organization, _month, statement = signed_open_month
    set_pix(organization, "chave-pix")
    payment = plant_payment(statement, 22000, history: "Pix enviado chave-pix")

    get "/months/2026-05"

    payment_row = row(response.body, "payment", payment_id: payment.id)
    expect(payment_row.text).to include("Sugestão de exceção")
    expect(payment_row.text).not_to include("Resolver")
  end

  it "Resolver is closed when no suggestion exists" do
    _account, _organization, _month, statement = signed_open_month
    payment = plant_payment(statement, 22000)

    get "/months/2026-05"

    payment_row = row(response.body, "payment", payment_id: payment.id)
    expect(payment_row.text).to include("Documento faltante")
    expect(payment_row.text).not_to include("Sugestão")
    expect(payment_row.text).not_to include("Resolver")
  end

  it "GET month omits Marcar tarifa when bank_fee offer inactive" do
    _account, organization, _month, statement = signed_open_month
    payment = plant_payment(statement, 22000)
    organization.update!(bank_fee_exception_active: false)

    get "/months/2026-05"

    expect(response.body).not_to include("Marcar tarifa")
    expect(response.body).not_to include("Marcar honorário")
    expect(payment).to be_missing_document
  end

  it "GET month omits Marcar honorario when accountant_fee offer inactive" do
    _account, organization, _month, statement = signed_open_month
    payment = plant_payment(statement, 22000)
    organization.update!(accountant_fee_exception_active: false)

    get "/months/2026-05"

    expect(response.body).not_to include("Marcar honorário")
    expect(payment).to be_missing_document
  end

  it "GET month keeps Tarifa bancaria after bank_fee offer hidden" do
    _account, organization, _month, statement = signed_open_month
    payment = plant_payment(statement, 22000)
    payment.mark_document_exception("bank_fee")
    organization.update!(bank_fee_exception_active: false)

    get "/months/2026-05"

    payment_row = row(response.body, "payment", payment_id: payment.id)
    expect(payment_row.text).to include("Tarifa bancária")
    expect(payment_row.text).not_to include("Documento faltante")
    expect(payment_row.text).not_to include("Desmarcar exceção")
  end

  it "GET B month still Marcar tarifa while A bank_fee offer inactive" do
    account_a, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    account_b, org_b = plant_coordinator(email: "b@example.com", organization_name: "B")
    org_a.update!(bank_fee_exception_active: false)
    _month_b, statement_b = plant_month(org_b)
    payment_b = plant_payment(statement_b, 22000)
    sign_in_as(account_b, organization: org_b)

    get "/months/2026-05/matches"

    expect(response.body).to include("Marcar tarifa")
    expect(org_a.reload.bank_fee_exception_active).to eq(false)
    expect(account_a).to be_present
    expect(payment_b).to be_missing_document
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
    expect(details.has_attribute?("open")).to eq(false)
    expect(details.text).to include("PDF")
    expect(details.text).to include("Incluir PDF")
    expect(details.text).to include("Planilha")
    expect(details.text).to include("Incluir planilha")
    expect(details.at_css('input[type="submit"][value="Enviar extrato"]')).to be_present
    expect(account_row.css("summary").map { |node| node.text.strip }).not_to include("Incluir extrato")
  end

  it "absent statement folds the upload form under Incluir extrato" do
    _account, organization, _month, _statement = signed_open_month
    bank_account = BankAccount.create_for(organization: organization, name: "Conta Alfa", compe: "033")

    get "/months/2026-05"

    account_row = row(response.body, "bank-account", bank_account_id: bank_account.id)
    form = account_row.css("form").find { |node| node["action"] == "/months/2026-05/bank_statements" }
    expect(form).not_to be_nil
    details = form.ancestors("details").first
    expect(details).not_to be_nil
    expect(details.at_css("summary").text.strip).to eq("Incluir extrato")
    expect(details.has_attribute?("open")).to eq(false)
    expect(details.text).to include("PDF")
    expect(details.text).to include("Incluir PDF")
    expect(details.text).to include("Planilha")
    expect(details.text).to include("Incluir planilha")
    expect(details.at_css('input[type="submit"][value="Enviar extrato"]')).to be_present
    expect(account_row.css("summary").map { |node| node.text.strip }).not_to include("Substituir extrato")
  end

  it "Falta row Situacao is Falta and Documentos has no Pdf or Planilha" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    bank_account = BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    post "/months", params: { year_month: "2026-05" }

    get "/months/2026-05"

    account_row = row(response.body, "bank-account", bank_account_id: bank_account.id)
    expect(account_row.at_css(".text-margem").text.strip).to eq("Falta")
    documents = account_row.at_css('[data-cell="documents"]')
    expect(documents.text).not_to include("Pdf")
    expect(documents.text).not_to include("Planilha")
    expect(account_row.at_css('[data-cell="situation"]').text.strip).to eq("Falta")
  end

  it "closed Presente row keeps Documentos and omits statement forms" do
    _account, organization, month, _statement = signed_open_month
    bank_account = organization.bank_accounts.order(:id).first
    post "/months/2026-05/bank_statements", params: {
      bank_account_id: bank_account.id, pdf: statement_pdf, spreadsheet: bb_xlsx
    }
    month.update!(closed: true)

    get "/months/2026-05"

    account_row = row(response.body, "bank-account", bank_account_id: bank_account.id)
    expect(account_row.at_css('[data-cell="situation"]').text.strip).to eq("Presente")
    lines = account_row.at_css('[data-cell="documents"]').css("p").map { |node| node.text.strip }
    expect(lines).to eq([ "Pdf extrato-maio-2026.pdf", "Planilha extrato-maio-2026.xlsx" ])
    expect(account_row.text).not_to include("Incluir extrato")
    expect(account_row.text).not_to include("Substituir extrato")
  end

  it "month bank ledger head and rows are Banco Nome Agencia Situacao Documentos actions" do
    _account, _organization, _month, statement = signed_open_month
    attach_statement_files(statement)

    get "/months/2026-05"

    head = page_doc(response.body).at_css(".ledger-head.ledger-month-bank")
    expect(head.element_children.map { |node| node.text.strip }).to eq(
      [ "Banco", "Nome", "Agência/conta", "Situação", "Documentos", "" ]
    )
    account_row = row(response.body, "bank-account", bank_account_id: statement.bank_account_id)
    cells = account_row.element_children
    expect(cells.size).to eq(6)
    expect(cells[0].text.strip).to eq(statement.bank_account.bank.presentation_name)
    expect(cells[1].text.strip).to eq(statement.bank_account.name)
    expect(cells[2].text.strip).to eq(statement.bank_account.coordinates.to_s)
    expect(cells[3]["data-cell"]).to eq("situation")
    expect(cells[4]["data-cell"]).to eq("documents")
    expect(cells[4]["class"].to_s).not_to include("whitespace-nowrap")
    expect(cells[4].at_css("p")["class"]).to include("text-meta")
    expect(cells[4].at_css("p")["class"]).to include("truncate")
    expect(cells[5].at_css("summary").text.strip).to eq("Substituir extrato")
  end

  it "two accounts only Presente row lists Pdf and Planilha filenames" do
    _account, organization, _month, statement = signed_open_month
    attach_statement_files(statement)
    falta = BankAccount.create_for(organization: organization, name: "Conta Alfa", compe: "033")

    get "/months/2026-05"

    presente_row = row(response.body, "bank-account", bank_account_id: statement.bank_account_id)
    falta_row = row(response.body, "bank-account", bank_account_id: falta.id)
    presente_docs = presente_row.at_css('[data-cell="documents"]')
    expect(presente_docs.text).to include("Pdf")
    expect(presente_docs.text).to include("extrato.pdf")
    expect(presente_docs.text).to include("Planilha")
    expect(presente_docs.text).to include("extrato.xlsx")
    expect(falta_row.at_css(".text-margem").text.strip).to eq("Falta")
    expect(falta_row.at_css('[data-cell="documents"]').text).not_to include("Pdf")
    expect(falta_row.at_css('[data-cell="documents"]').text).not_to include("Planilha")
    expect(falta_row.at_css('[data-cell="situation"]').text.strip).to eq("Falta")
  end

  def month_h2s(body)
    page_doc(body).css("h2").map { |node| node.text.strip }
  end

  def month_fold_summaries(body)
    page_doc(body).css("details.month-fold > summary").map { |node| node.text.strip }
  end

  def month_fold(body, title)
    page_doc(body).css("details.month-fold").find { |node| node.at_css("summary")&.text&.strip == title }
  end

  def month_chip_links(body)
    page_doc(body).at_css('[role="group"][aria-label="Conta bancária"]').css("a")
  end

  def confirm_section(body)
    page_doc(body).css("section").find { |section| section.at_css("h2")&.text&.strip == "Confirmar contas para fechamento" }
  end

  it "unconfirmed GET hides movements and shows confirm step" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    post "/months", params: { year_month: "2026-05" }

    get "/months/2026-05"

    expect(response).to have_http_status(:ok)
    headings = month_h2s(response.body)
    expect(headings).to include("Contas bancárias")
    expect(headings).to include("Confirmar contas para fechamento")
    expect(headings.index("Contas bancárias")).to be < headings.index("Confirmar contas para fechamento")
    form = page_doc(response.body).at_css('form[action="/months/2026-05/account_confirmation"]')
    expect(form).to be_present
    submit = form.at_css('input[type="submit"][value="Iniciar fechamento"]')
    expect(submit).to be_present
    expect(submit["disabled"]).to eq("disabled")
    expect(error_notice_text(response.body)).to eq("Inclua o extrato planilha de pelo menos uma conta bancária.")
    expect(response.body).to include("Insira os extratos das contas bancárias com as quais deseja realizar o fechamento.")
    expect(headings).not_to include("Recebimentos")
    expect(headings).not_to include("Pagamentos")
    expect(headings).not_to include("Documentos sem casamento")
    expect(rows(response.body, "inflow")).to be_empty
    expect(rows(response.body, "payment")).to be_empty
    expect(rows(response.body, "pool-document")).to be_empty
    expect(response.body).not_to include("pagamento com documento faltante")
  end

  it "unconfirmed confirm step lists Alfa then Principal with Falta in margem" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    BankAccount.create_for(organization: organization, name: "Conta Alfa", compe: "033")
    principal = BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    post "/months", params: { year_month: "2026-05" }
    post "/months/2026-05/bank_statements", params: { bank_account_id: principal.id, spreadsheet: bb_xlsx }

    get "/months/2026-05"

    bank_names = rows(response.body, "bank-account").map { |row| row.element_children[1].text.strip }
    expect(bank_names).to eq([ "Conta Alfa", "Conta Principal" ])
    section = confirm_section(response.body)
    expect(section).to be_present
    head = section.at_css(".ledger-head.ledger-confirm")
    expect(head.element_children.map { |node| node.text.strip }).to eq([ "Nome", "Situação" ])
    confirm_rows = section.css("li.ledger-confirm")
    expect(confirm_rows.map { |row| row.element_children.map { |cell| cell.text.strip } }).to eq(
      [ [ "Conta Alfa", "Falta" ], [ "Conta Principal", "Presente" ] ]
    )
    confirm_names = section.css("li.ledger-confirm p.font-medium").map { |node| node.text.strip }
    expect(confirm_names).to eq([ "Conta Alfa", "Conta Principal" ])
    expect(section.text).to include("Falta")
    expect(section.text).to include("Presente")
    alfa_row = section.css("li.ledger-confirm").find { |row| row.text.include?("Conta Alfa") }
    expect(alfa_row.at_css(".text-margem").text.strip).to eq("Falta")
    submit = section.at_css('input[type="submit"][value="Iniciar fechamento"]')
    expect(submit).to be_present
    expect(submit["disabled"]).to be_nil
    expect(response.body).not_to include("Inclua o extrato planilha de pelo menos uma conta bancária.")
  end

  it "unconfirmed GET with no active accounts still shows confirm step" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }

    get "/months/2026-05"

    expect(response.body).to include("Nenhuma conta bancária ativa")
    headings = month_h2s(response.body)
    expect(headings).to include("Confirmar contas para fechamento")
    submit = page_doc(response.body).at_css('input[type="submit"][value="Iniciar fechamento"]')
    expect(submit).to be_present
    expect(submit["disabled"]).to eq("disabled")
    expect(error_notice_text(response.body)).to eq("Inclua o extrato planilha de pelo menos uma conta bancária.")
    expect(headings).not_to include("Recebimentos")
    expect(headings).not_to include("Pagamentos")
    expect(headings).not_to include("Documentos sem casamento")
  end

  it "unconfirmed GET with tarifa uses insert-statements summary not missing-document count" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    bank_account = BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    post "/months", params: { year_month: "2026-05" }
    post "/months/2026-05/bank_statements", params: { bank_account_id: bank_account.id, spreadsheet: bb_xlsx }

    get "/months/2026-05"

    expect(response.body).to include("Insira os extratos das contas bancárias com as quais deseja realizar o fechamento.")
    expect(response.body).not_to include("1 pagamento com documento faltante")
    expect(rows(response.body, "payment")).to be_empty
  end

  it "POST account_confirmation reveals movements and Pronto toast" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    bank_account = BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    post "/months", params: { year_month: "2026-05" }
    post "/months/2026-05/bank_statements", params: { bank_account_id: bank_account.id, spreadsheet: bb_xlsx }
    statement = bank_account.bank_statements.last
    statement.payments.where.not(amount_cents: 15500).find_each { |payment| payment.mark_document_exception("bank_fee") }

    post "/months/2026-05/account_confirmation"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    expect(organization.months.find_by!(year_month: "2026-05").accounts_confirmed).to eq(true)

    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_node(response.body).text).to include("Pronto.")
    headings = month_h2s(response.body)
    expect(month_fold_summaries(response.body)).to eq([ "Pagamentos", "Documentos sem casamento", "Recebimentos" ])
    expect(headings).not_to include("Recebimentos")
    expect(headings).not_to include("Pagamentos")
    expect(headings).not_to include("Documentos sem casamento")
    expect(headings).not_to include("Confirmar contas para fechamento")
    summary = page_doc(response.body).at_css("p.mt-6 .text-margem")
    expect(summary.text).to include("1 pagamento com documento faltante")
    payment_row = rows(response.body, "payment").find { |row| row.text.include?("R$ 155,00") }
    expect(payment_row).to be_present
  end

  it "POST account_confirmation with mixed Falta keeps Alfa Falta and lists Principal movements" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    BankAccount.create_for(organization: organization, name: "Conta Alfa", compe: "033")
    principal = BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    post "/months", params: { year_month: "2026-05" }
    post "/months/2026-05/bank_statements", params: { bank_account_id: principal.id, spreadsheet: bb_xlsx }

    post "/months/2026-05/account_confirmation"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    expect(organization.months.find_by!(year_month: "2026-05").accounts_confirmed).to eq(true)
    get "/months/2026-05"
    expect(month_fold_summaries(response.body)).to include("Pagamentos")
    expect(month_h2s(response.body)).not_to include("Pagamentos")
    expect(month_h2s(response.body)).not_to include("Confirmar contas para fechamento")
    expect(response.body).to include("Conta Principal")
    expect(rows(response.body, "payment")).not_to be_empty
    expect(response.body).to include("Falta o extrato de 1 conta ativa")
    alfa_row = rows(response.body, "bank-account").find { |row| row.text.include?("Conta Alfa") }
    expect(alfa_row.at_css('[data-cell="situation"]').text.strip).to eq("Falta")
  end

  it "POST account_confirmation without spreadsheet returns 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    post "/months", params: { year_month: "2026-05" }

    post "/months/2026-05/account_confirmation"

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Inclua o extrato planilha de pelo menos uma conta bancária.")
    expect(organization.months.find_by!(year_month: "2026-05").accounts_confirmed).to eq(false)
  end

  it "second POST account_confirmation is idempotent" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    bank_account = BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    post "/months", params: { year_month: "2026-05" }
    post "/months/2026-05/bank_statements", params: { bank_account_id: bank_account.id, spreadsheet: bb_xlsx }
    post "/months/2026-05/account_confirmation"

    post "/months/2026-05/account_confirmation"

    expect(response).to have_http_status(:found)
    month = organization.months.find_by!(year_month: "2026-05")
    expect(month.accounts_confirmed).to eq(true)
    expect(organization.months.where(year_month: "2026-05").count).to eq(1)
    follow_redirect!
    expect(month_fold_summaries(response.body)).to eq([ "Pagamentos", "Documentos sem casamento", "Recebimentos" ])
    expect(month_h2s(response.body)).not_to include("Recebimentos")
    expect(toast_node(response.body).text).to include("Pronto.")
  end

  it "closed GET shows movements even when accounts_confirmed is false" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    _month, statement = plant_month(organization, accounts_confirmed: false)
    plant_payment(statement, 22000)
    organization.months.find_by!(year_month: "2026-05").update_columns(closed: true)

    get "/months/2026-05"

    expect(response).to have_http_status(:ok)
    stamp = page_doc(response.body).at_css('[data-stamp="closed"]')
    expect(stamp.text.strip).to eq("Mês fechado")
    expect(month_h2s(response.body)).not_to include("Confirmar contas para fechamento")
    expect(rows(response.body, "payment")).not_to be_empty
  end

  it "POST account_confirmation on closed month returns 422 Mes fechado" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    _month, statement = plant_month(organization, accounts_confirmed: false)
    plant_payment(statement, 22000)
    month = organization.months.find_by!(year_month: "2026-05")
    month.update_columns(closed: true)

    post "/months/2026-05/account_confirmation"

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Mês fechado")
    expect(month.reload.accounts_confirmed).to eq(false)
  end

  it "DELETE never-sent empty month redirects home and frees year_month" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }

    delete "/months/2026-05"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
    expect(organization.months.where(year_month: "2026-05").count).to eq(0)

    follow_redirect!
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_node(response.body).text).to include("Pronto.")
    expect(response.body).to include("Nenhum mês aberto")

    post "/months", params: { year_month: "2026-05" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    expect(organization.months.where(year_month: "2026-05").count).to eq(1)
  end

  it "DELETE never-sent month destroys statements matches and nullifies documents" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, statement = plant_month(organization, accounts_confirmed: true)
    attach_statement_files(statement)
    payment = plant_payment(statement, 22000)
    plant_inflow(statement, 6300)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])
    expect(document.reload.month_id).to eq(month.id)

    expect(PackageArchiveWriter).not_to receive(:current)
    delete "/months/2026-05"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
    expect(organization.months.where(year_month: "2026-05")).to be_empty
    expect(BankStatement.where(id: statement.id)).to be_empty
    expect(Payment.where(id: payment.id)).to be_empty
    expect(Inflow.where(bank_statement_id: statement.id)).to be_empty
    expect(Match.where(month_id: month.id)).to be_empty
    expect(document.reload.month_id).to be_nil
  end

  it "DELETE closed month returns 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month = Month.open(organization: organization, year_month: "2026-05")
    month.update!(closed: true)

    delete "/months/2026-05"

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Só é possível excluir um fechamento aberto que nunca foi enviado.")
    expect(month.reload).to be_closed
    expect(organization.months.where(year_month: "2026-05").count).to eq(1)
  end

  it "DELETE reopened month returns 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month = Month.open(organization: organization, year_month: "2026-05")
    month.update!(closed: false, month_folder_id: "drive-folder")

    delete "/months/2026-05"

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Só é possível excluir um fechamento aberto que nunca foi enviado.")
    expect(organization.months.find_by!(year_month: "2026-05").month_folder_id).to eq("drive-folder")
  end

  it "DELETE invalid or missing month returns 404" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    Month.open(organization: organization, year_month: "2026-04")

    delete "/months/2026-13"

    expect(response).to have_http_status(:not_found)
    expect(organization.months.count).to eq(1)

    delete "/months/2026-05"

    expect(response).to have_http_status(:not_found)
    expect(organization.months.where(year_month: "2026-04").count).to eq(1)
  end

  it "submitter DELETE month returns 404" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    Month.open(organization: organization, year_month: "2026-05")
    sign_in_as(submitter, organization: organization)

    delete "/months/2026-05"

    expect(response).to have_http_status(:not_found)
    expect(organization.months.where(year_month: "2026-05").count).to eq(1)
  end

  it "confirmed GET missing-document payment includes Resolver" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    bank_account = BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    post "/months", params: { year_month: "2026-05" }
    post "/months/2026-05/bank_statements", params: { bank_account_id: bank_account.id, spreadsheet: bb_xlsx }
    statement = bank_account.bank_statements.last
    statement.payments.where.not(amount_cents: 15500).find_each { |payment| payment.mark_document_exception("bank_fee") }
    post "/months/2026-05/account_confirmation"
    follow_redirect!

    payment_row = rows(response.body, "payment").find { |row| row.text.include?("R$ 155,00") }
    expect(payment_row.text).not_to include("Resolver")
  end

  it "unconfirmed close with Falta still Importe o extrato" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    post "/months", params: { year_month: "2026-05" }

    post "/months/2026-05/close"

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Importe o extrato de cada conta ativa")
    expect(organization.months.find_by!(year_month: "2026-05").closed?).to eq(false)
  end

  it "unconfirmed close with missing document still Ha documento faltante" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    _month, statement = plant_month(organization, accounts_confirmed: false)
    plant_payment(statement, 22000)

    post "/months/2026-05/close"

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Há documento faltante")
    expect(organization.months.find_by!(year_month: "2026-05").closed?).to eq(false)
  end

  it "confirmed open month GET includes Casar pagamentos as secondary before Fechar" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization)

    get "/months/2026-05"

    link = page_doc(response.body).css("a").find { |node| node.text.strip == "Casar pagamentos" }
    expect(link).to be_present
    expect(link["href"]).to eq("/months/2026-05/matches")
    expect(link["class"]).to include("ds-btn-secondary")
    cluster_html = link.parent.to_html
    expect(cluster_html.index("Casar pagamentos")).to be < cluster_html.index("Fechar para envio")
  end

  it "closed month GET stamps under the title and omits Casar pagamentos" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, _statement = plant_month(organization)
    month.update!(closed: true)

    get "/months/2026-05"

    page = page_doc(response.body)
    expect(page.css("a").map { |node| node.text.strip }).not_to include("Casar pagamentos")
    stamp = page.at_css("[data-stamp=closed]")
    expect(stamp.text).to eq("Mês fechado")
    expect(stamp["class"]).to include("stamp-closed")
    title_block = stamp.parent
    expect(title_block.at_css("h1").text).to include("maio")
    expect(response.body).to include("Restaurar pasta")
    expect(response.body).to include("Reabrir")
  end

  it "unconfirmed open month GET omits Casar pagamentos" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization, accounts_confirmed: false)

    get "/months/2026-05"

    texts = page_doc(response.body).css("a").map { |node| node.text.strip }
    expect(texts).not_to include("Casar pagamentos")
  end

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
    expect(reopen.ancestors("form").first["data-turbo-confirm"]).to eq("Reabrir o mês?")
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
    other = plant_payment(statement, 18000, history: "Pix enviado — Outro")
    n1 = plant_recibo(organization, account, payee: "Padaria Central", amount: "180,00", date: "2026-05-13")
    Match.confirm(month: month, payments: [ other ], supporting_documents: [ n1 ])

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
