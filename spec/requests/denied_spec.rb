require "rails_helper"

RSpec.describe "Denied", type: :request do
  it "GET /denied responds 200 with nao foi convidado" do
    get "/denied"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("não foi convidado")
  end

  it "GET /denied renders the header without nav and the denied sentence" do
    get "/denied"

    expect(response).to have_http_status(:ok)
    header = Nokogiri::HTML(response.body).at_css("header")
    expect(header).not_to be_nil
    expect(header.text).to include("Fechamento mensal")
    expect(header.at_css("nav")).to be_nil
    expect(response.body).to include("Você não foi convidado a usar este sistema.")
  end
end
