require "rails_helper"

RSpec.describe "Matches workspace", type: :request do
  before do
    @account, @organization = plant_coordinator
    sign_in_as(@account, organization: @organization)
    @month, @statement = plant_month(@organization)
  end

  it "selects oldest pending payment even without a suggestion and breaks ties by id" do
    first = plant_payment(@statement, 1100, history: "Mais antigo", occurred_on: Date.new(2026, 5, 1))
    plant_payment(@statement, 1200, history: "Mesmo dia", occurred_on: Date.new(2026, 5, 1))
    plant_payment(@statement, 1300, history: "Mais recente", occurred_on: Date.new(2026, 5, 2))
    get "/months/2026-05/matches"
    expect(response).to have_http_status(:ok)
    expect(page_doc(response.body).at_css('[data-current="true"]')['data-payment-id']).to eq(first.id.to_s)
  end

  it "limits selectable unmatched documents to this organization and month" do
    plant_payment(@statement, 10000)
    included = plant_recibo(@organization, @account, payee: "Documento elegível", amount: "100,00")
    other_month, = plant_month(@organization, year_month: "2026-04")
    other_month_document = plant_recibo(@organization, @account, payee: "Outro mês", amount: "110,00")
    other_month_document.update!(month_id: other_month.id)
    foreign_account, foreign_organization = plant_coordinator(email: "foreign@example.com", organization_name: "ONG Sul")
    foreign = plant_recibo(foreign_organization, foreign_account, payee: "Outra organização", amount: "120,00")
    get "/months/2026-05/matches"
    ids = page_doc(response.body).css('[data-row="pool-document"]').map { |row| row['data-document-id'].to_i }
    expect(ids).to include(included.id)
    expect(ids).not_to include(other_month_document.id, foreign.id)
  end

  it "rerenders the matches screen when exception selection is invalid" do
    payment = plant_payment(@statement, 10000)
    post "/months/2026-05/document_exceptions", params: { screen: "matches", payment_ids: [], kind: "bank_fee" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Selecione um pagamento para marcar a exceção.")
    expect(payment.reload).to be_missing_document
  end

  it "rerenders a closed month when exception marking is refused" do
    payment = plant_payment(@statement, 10000)
    @month.update!(closed: true)
    post "/months/2026-05/document_exceptions", params: { screen: "matches", payment_ids: [ payment.id ], kind: "bank_fee" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Mês fechado")
    expect(payment.reload).to be_missing_document
  end
end
