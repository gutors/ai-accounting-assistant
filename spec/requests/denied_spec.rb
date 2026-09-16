require "rails_helper"

RSpec.describe "Denied", type: :request do
  it "GET /denied responds 200 with nao foi convidado" do
    get "/denied"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("não foi convidado")
  end
end
