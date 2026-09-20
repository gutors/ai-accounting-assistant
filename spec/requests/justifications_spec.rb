require "rails_helper"

RSpec.describe "Justifications", type: :request do
  def signed_submitter
    _coord, organization = plant_coordinator
    account, _ = plant_submitter(organization: organization)
    sign_in_as(account, organization: organization)
    [ account, organization ]
  end

  def insert_own(payee:, amount:)
    post "/supporting_documents", params: {
      kind: "recibo", amount: amount, date: "2026-05-11", payee: payee, photo: photo_named("recibo-#{payee.parameterize}.jpg")
    }
    SupportingDocument.find_by!(payee: payee)
  end

  it "POST justification of 200,00 with two documents redirects" do
    account, organization = signed_submitter
    doc_a = insert_own(payee: "Padaria Central", amount: "155,00")
    doc_b = insert_own(payee: "Mercado Silva", amount: "45,00")

    post "/justifications", params: {
      amount: "200,00", supporting_document_ids: [ doc_a.id, doc_b.id ]
    }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    justification = Justification.find_by!(account: account, organization: organization)
    expect(justification.amount_cents).to eq(20000)
    expect(doc_a.reload.justification).to eq(justification)
    expect(doc_b.reload.justification).to eq(justification)
    get "/supporting_documents"
    expect(response.body).to include("R$ 200,00")
  end

  it "POST justification of 155,00 with one document persists 15500" do
    _account, _organization = signed_submitter
    document = insert_own(payee: "Padaria Central", amount: "155,00")

    post "/justifications", params: {
      amount: "155,00", supporting_document_ids: [ document.id ]
    }

    expect(Justification.last.amount_cents).to eq(15500)
  end

  it "POST justification without document ids returns 422" do
    signed_submitter

    expect do
      post "/justifications", params: { amount: "200,00", supporting_document_ids: [] }
    end.not_to change(Justification, :count)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "POST justification with another Account document returns 422" do
    coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(coord, organization: organization)
    post "/supporting_documents", params: {
      kind: "recibo", amount: "155,00", date: "2026-05-11", payee: "Doc Alheio", photo: photo_named("alheio.jpg")
    }
    foreign = SupportingDocument.last
    sign_in_as(submitter, organization: organization)

    expect do
      post "/justifications", params: {
        amount: "155,00", supporting_document_ids: [ foreign.id ]
      }
    end.not_to change(Justification, :count)

    expect(foreign.reload.justification_id).to be_nil
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "POST justification with month document returns 422" do
    account, organization = signed_submitter
    document = insert_own(payee: "Padaria Central", amount: "155,00")
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 15500)
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ])

    expect do
      post "/justifications", params: {
        amount: "155,00", supporting_document_ids: [ document.id ]
      }
    end.not_to change(Justification, :count)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "POST justification with already justified document returns 422" do
    _account, _organization = signed_submitter
    document = insert_own(payee: "Padaria Central", amount: "155,00")
    post "/justifications", params: {
      amount: "155,00", supporting_document_ids: [ document.id ]
    }
    original = document.reload.justification

    expect do
      post "/justifications", params: {
        amount: "155,00", supporting_document_ids: [ document.id ]
      }
    end.not_to change(Justification, :count)

    expect(document.reload.justification).to eq(original)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "POST justification with invalid spent amount returns 422" do
    _account, _organization = signed_submitter
    document = insert_own(payee: "Padaria Central", amount: "155,00")

    [ "0", "not-an-amount" ].each do |amount|
      expect do
        post "/justifications", params: {
          amount: amount, supporting_document_ids: [ document.id ]
        }
      end.not_to change(Justification, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  it "submitter GET /supporting_documents omits another Account justification" do
    _coord, organization = plant_coordinator
    other, _ = plant_submitter(email: "other@example.com", organization: organization)
    submitter, _ = plant_submitter(email: "sub@example.com", organization: organization)
    sign_in_as(other, organization: organization)
    document = insert_own(payee: "Outro Doc", amount: "80,00")
    post "/justifications", params: {
      amount: "80,00", supporting_document_ids: [ document.id ]
    }
    sign_in_as(submitter, organization: organization)

    get "/supporting_documents"

    expect(response.body).not_to include("R$ 80,00")
  end

  it "DELETE last member document destroys the Justification" do
    _account, _organization = signed_submitter
    document = insert_own(payee: "Padaria Central", amount: "155,00")
    post "/justifications", params: {
      amount: "155,00", supporting_document_ids: [ document.id ]
    }
    expect(Justification.count).to eq(1)

    delete "/supporting_documents/#{document.id}"

    expect(Justification.count).to eq(0)
  end

  it "coordinator GET /supporting_documents includes justification and member payees" do
    coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)
    doc_a = insert_own(payee: "Padaria Central", amount: "155,00")
    doc_b = insert_own(payee: "Mercado Silva", amount: "45,00")
    post "/justifications", params: {
      amount: "200,00", supporting_document_ids: [ doc_a.id, doc_b.id ]
    }
    sign_in_as(coord, organization: organization)

    get "/supporting_documents"

    expect(response.body).to include("R$ 200,00")
    expect(response.body).to include("Padaria Central")
    expect(response.body).to include("Mercado Silva")
  end

  it "PATCH justification spent amount 180,00 redirects" do
    _account, _organization = signed_submitter
    document = insert_own(payee: "Padaria Central", amount: "155,00")
    post "/justifications", params: {
      amount: "200,00", supporting_document_ids: [ document.id ]
    }
    justification = Justification.last

    patch "/justifications/#{justification.id}", params: { amount: "180,00" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/supporting_documents")
    expect(justification.reload.amount_cents).to eq(18000)
    get "/supporting_documents"
    expect(response.body).to include("R$ 180,00")
    expect(response.body).not_to include("R$ 200,00")
  end

  it "PATCH justification with a month member returns 422" do
    _account, organization = signed_submitter
    document = insert_own(payee: "Padaria Central", amount: "155,00")
    post "/justifications", params: {
      amount: "200,00", supporting_document_ids: [ document.id ]
    }
    justification = Justification.last
    month, statement = plant_month(organization)
    payment = plant_payment(statement, 15500)
    Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document.reload ])

    patch "/justifications/#{justification.id}", params: { amount: "180,00" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(justification.reload.amount_cents).to eq(20000)
  end

  it "PATCH another Account justification returns 404" do
    _coord, organization = plant_coordinator
    other, _ = plant_submitter(email: "other@example.com", organization: organization)
    submitter, _ = plant_submitter(email: "sub@example.com", organization: organization)
    sign_in_as(other, organization: organization)
    document = insert_own(payee: "Outro Doc", amount: "80,00")
    post "/justifications", params: {
      amount: "80,00", supporting_document_ids: [ document.id ]
    }
    justification = Justification.last
    sign_in_as(submitter, organization: organization)

    patch "/justifications/#{justification.id}", params: { amount: "90,00" }

    expect(response).to have_http_status(:not_found)
    expect(justification.reload.amount_cents).to eq(8000)
  end

  it "justification row carries data-row hook" do
    _account, _organization = signed_submitter
    document = insert_own(payee: "Padaria Central", amount: "80,00")
    post "/justifications", params: { amount: "80,00", supporting_document_ids: [ document.id ] }
    justification = Justification.last

    get "/supporting_documents"

    justification_row = row(response.body, "justification", justification_id: justification.id)
    expect(justification_row).not_to be_nil
    expect(justification_row.text).to include("R$ 80,00", "Padaria Central")
  end
end
