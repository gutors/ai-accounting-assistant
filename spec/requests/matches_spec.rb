require "rails_helper"

RSpec.describe "Matches", type: :request do
  def signed_month
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, statement = plant_month(organization)
    [ account, organization, month, statement ]
  end

  it "POST 1 payment 2 documents persists Casado and redirects" do
    account, organization, _month, statement = signed_month
    payment = plant_payment(statement, 22000)
    doc_a = plant_recibo(organization, account, payee: "Padaria A", amount: "100,00")
    doc_b = plant_recibo(organization, account, payee: "Padaria B", amount: "120,00")

    post "/months/2026-05/matches", params: {
      payment_ids: [ payment.id ], supporting_document_ids: [ doc_a.id, doc_b.id ]
    }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    expect(Match.count).to eq(1)

    get "/months/2026-05"
    expect(response.body).to include("Casado")
    expect(response.body).to include("Padaria A")
    expect(response.body).to include("Padaria B")
    expect(response.body).not_to include("Documento faltante")
  end

  it "POST match removes both payees from unmatched pool" do
    account, organization, _month, statement = signed_month
    payment = plant_payment(statement, 22000)
    doc_a = plant_recibo(organization, account, payee: "Padaria A", amount: "100,00")
    doc_b = plant_recibo(organization, account, payee: "Padaria B", amount: "120,00")

    post "/months/2026-05/matches", params: {
      payment_ids: [ payment.id ], supporting_document_ids: [ doc_a.id, doc_b.id ]
    }
    get "/months/2026-05"

    expect(pool_html(response.body)).not_to include("Padaria A")
    expect(pool_html(response.body)).not_to include("Padaria B")
  end

  it "POST lesser with observation persists and shows desconto nao documentado" do
    account, organization, _month, statement = signed_month
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "200,00")

    post "/months/2026-05/matches", params: {
      payment_ids: [ payment.id ],
      supporting_document_ids: [ document.id ],
      observation: "desconto não documentado"
    }

    expect(response).to have_http_status(:found)
    expect(Match.count).to eq(1)
    get "/months/2026-05"
    expect(response.body).to include("desconto não documentado")
  end

  it "POST lesser without observation returns 422 Informe a observacao do casamento" do
    account, organization, _month, statement = signed_month
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "200,00")

    post "/months/2026-05/matches", params: {
      payment_ids: [ payment.id ], supporting_document_ids: [ document.id ]
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Informe a observação do casamento")
    expect(Match.count).to eq(0)
  end

  it "POST greater without observation persists Match 302" do
    account, organization, _month, statement = signed_month
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "250,00")

    post "/months/2026-05/matches", params: {
      payment_ids: [ payment.id ], supporting_document_ids: [ document.id ]
    }

    expect(response).to have_http_status(:found)
    expect(Match.count).to eq(1)
  end

  it "POST 1 payment 1 document equal persists Match 302" do
    account, organization, _month, statement = signed_month
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    post "/months/2026-05/matches", params: {
      payment_ids: [ payment.id ], supporting_document_ids: [ document.id ]
    }

    expect(response).to have_http_status(:found)
    expect(Match.count).to eq(1)
  end

  it "POST 1 payment 0 documents returns 422 Selecione ao menos um documento" do
    _account, _organization, _month, statement = signed_month
    payment = plant_payment(statement, 22000)

    post "/months/2026-05/matches", params: { payment_ids: [ payment.id ] }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Selecione ao menos um documento")
    expect(Match.count).to eq(0)
  end

  it "DELETE match returns payments to Documento faltante and documents to pool" do
    account, organization, _month, statement = signed_month
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    post "/months/2026-05/matches", params: {
      payment_ids: [ payment.id ], supporting_document_ids: [ document.id ]
    }
    match = Match.last

    delete "/months/2026-05/matches/#{match.id}"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/months/2026-05")
    expect(Match.count).to eq(0)

    get "/months/2026-05"
    expect(response.body).to include("Documento faltante")
    expect(pool_html(response.body)).to include("Padaria Central")

    get "/supporting_documents"
    expect(response.body).not_to include("Casado em 2026-05")
  end

  it "POST match for already matched payment returns 422 Pagamento ja esta em um casamento" do
    account, organization, _month, statement = signed_month
    payment = plant_payment(statement, 22000)
    first_doc = plant_recibo(organization, account, payee: "Padaria A", amount: "220,00")
    second_doc = plant_recibo(organization, account, payee: "Padaria B", amount: "220,00")
    post "/months/2026-05/matches", params: {
      payment_ids: [ payment.id ], supporting_document_ids: [ first_doc.id ]
    }

    post "/months/2026-05/matches", params: {
      payment_ids: [ payment.id ], supporting_document_ids: [ second_doc.id ]
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Pagamento já está em um casamento")
    expect(Match.count).to eq(1)
  end

  it "POST match for already matched document returns 422 Documento ja esta em um casamento" do
    account, organization, _month, statement = signed_month
    payment_a = plant_payment(statement, 22000)
    payment_b = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    post "/months/2026-05/matches", params: {
      payment_ids: [ payment_a.id ], supporting_document_ids: [ document.id ]
    }

    post "/months/2026-05/matches", params: {
      payment_ids: [ payment_b.id ], supporting_document_ids: [ document.id ]
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Documento já está em um casamento")
    expect(Match.count).to eq(1)
  end

  it "unauthenticated POST /months/2026-05/matches responds 302 to /login" do
    expect do
      post "/months/2026-05/matches", params: { payment_ids: [ 1 ], supporting_document_ids: [ 1 ] }
    end.not_to change(Match, :count)

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "unauthenticated DELETE match responds 302 to /login and keeps the Match" do
    account, organization = plant_coordinator
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    match = Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])

    delete "/months/2026-05/matches/#{match.id}"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
    expect(Match.exists?(match.id)).to be true
  end

  it "POST 2 payments 1 document persists Casado on both" do
    account, organization, _month, statement = signed_month
    payment_a = plant_payment(statement, 10000)
    payment_b = plant_payment(statement, 12000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    post "/months/2026-05/matches", params: {
      payment_ids: [ payment_a.id, payment_b.id ], supporting_document_ids: [ document.id ]
    }

    expect(response).to have_http_status(:found)
    get "/months/2026-05"
    expect(response.body).to include("Casado")
    expect(response.body).not_to include("Documento faltante")
    expect(payment_a.reload.match_id).to be_present
    expect(payment_b.reload.match_id).to be_present
  end

  it "POST 3 payments 1 document persists Match 302" do
    account, organization, _month, statement = signed_month
    payments = [ 7000, 8000, 7000 ].map { |cents| plant_payment(statement, cents) }
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    post "/months/2026-05/matches", params: {
      payment_ids: payments.map(&:id), supporting_document_ids: [ document.id ]
    }

    expect(response).to have_http_status(:found)
    expect(Match.count).to eq(1)
  end

  it "POST 2 payments 2 documents returns 422 Casamento e um pagamento" do
    account, organization, _month, statement = signed_month
    payment_a = plant_payment(statement, 10000)
    payment_b = plant_payment(statement, 12000)
    doc_a = plant_recibo(organization, account, payee: "Padaria A", amount: "100,00")
    doc_b = plant_recibo(organization, account, payee: "Padaria B", amount: "120,00")

    post "/months/2026-05/matches", params: {
      payment_ids: [ payment_a.id, payment_b.id ], supporting_document_ids: [ doc_a.id, doc_b.id ]
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Casamento é um pagamento com um ou mais documentos, ou vários pagamentos com um documento")
    expect(Match.count).to eq(0)
  end

  it "POST 0 payments 1 document returns 422 Selecione ao menos um pagamento" do
    account, organization, _month, _statement = signed_month
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")

    post "/months/2026-05/matches", params: { supporting_document_ids: [ document.id ] }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Selecione ao menos um pagamento")
    expect(Match.count).to eq(0)
  end

  it "POST match on bank_fee payment clears Tarifa bancaria" do
    account, organization, _month, statement = signed_month
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    post "/months/2026-05/payments/#{payment.id}/document_exception", params: { kind: "bank_fee" }

    post "/months/2026-05/matches", params: {
      payment_ids: [ payment.id ], supporting_document_ids: [ document.id ]
    }

    expect(Match.count).to eq(1)
    expect(payment.reload.document_exception_kind).to be_nil
    get "/months/2026-05"
    expect(response.body).to include("Casado")
    expect(response.body).not_to include("Tarifa bancária")
  end

  it "POST match with another organization payment returns 404" do
    account, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    org_b = Organization.create!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    _month_b, statement_b = plant_month(org_b)
    foreign_payment = plant_payment(statement_b, 22000)
    sign_in_as(account, organization: org_a)
    plant_month(org_a)
    document = plant_recibo(org_a, account, payee: "Padaria Central", amount: "220,00")

    post "/months/2026-05/matches", params: {
      payment_ids: [ foreign_payment.id ], supporting_document_ids: [ document.id ]
    }

    expect(response).to have_http_status(:not_found)
    expect(foreign_payment.reload.match_id).to be_nil
    expect(Match.count).to eq(0)
  end

  it "POST match with another organization document returns 404" do
    account, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    org_b = Organization.create!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    foreign_doc = plant_recibo(org_b, account, payee: "Only Org B", amount: "220,00")
    sign_in_as(account, organization: org_a)
    _month, statement = plant_month(org_a)
    payment = plant_payment(statement, 22000)

    post "/months/2026-05/matches", params: {
      payment_ids: [ payment.id ], supporting_document_ids: [ foreign_doc.id ]
    }

    expect(response).to have_http_status(:not_found)
    expect(foreign_doc.reload.match_id).to be_nil
    expect(Match.count).to eq(0)
  end

  it "DELETE match of another organization returns 404" do
    account, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    org_b = Organization.create!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    month_b, statement_b = plant_month(org_b)
    payment_b = plant_payment(statement_b, 22000)
    document_b = plant_recibo(org_b, account, payee: "Only Org B", amount: "220,00")
    foreign_match = Match.confirm(month: month_b, payments: [ payment_b ], supporting_documents: [ document_b ])
    sign_in_as(account, organization: org_a)
    plant_month(org_a)

    delete "/months/2026-05/matches/#{foreign_match.id}"

    expect(response).to have_http_status(:not_found)
    expect(Match.exists?(foreign_match.id)).to be true
  end

  it "DELETE missing match id returns 404" do
    signed_month

    delete "/months/2026-05/matches/0"

    expect(response).to have_http_status(:not_found)
  end

  it "POST match while closed returns 422 Mes fechado" do
    account, organization, month, statement = signed_month
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    month.update!(closed: true)

    post "/months/2026-05/matches", params: {
      payment_ids: [ payment.id ], supporting_document_ids: [ document.id ]
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Mês fechado")
    expect(Match.count).to eq(0)
  end

  it "DELETE match while closed returns 422 Mes fechado" do
    account, organization, month, statement = signed_month
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    post "/months/2026-05/matches", params: {
      payment_ids: [ payment.id ], supporting_document_ids: [ document.id ]
    }
    match = Match.last
    month.update!(closed: true)

    delete "/months/2026-05/matches/#{match.id}"

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Mês fechado")
    expect(Match.exists?(match.id)).to eq(true)
  end

  it "submitter POST match persists no Match and responds 404" do
    account, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    _month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    document = plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    sign_in_as(submitter, organization: organization)

    expect do
      post "/months/2026-05/matches", params: {
        payment_ids: [ payment.id ], supporting_document_ids: [ document.id ]
      }
    end.not_to change(Match, :count)

    expect(response).to have_http_status(:not_found)
  end
end
