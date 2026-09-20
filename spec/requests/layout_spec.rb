require "rails_helper"

RSpec.describe "Layout header", type: :request do
  it "coordinator header names ONG Norte and links Inicio Documentos Configuracao and Sair" do
    account, organization = plant_coordinator(organization_name: "ONG Norte")
    sign_in_as(account, organization: organization)

    get "/"

    expect(response).to have_http_status(:ok)
    headers = Nokogiri::HTML(response.body).css("header")
    expect(headers.size).to eq(1)
    header = headers.first
    expect(header.text).to include("ONG Norte")
    expect(header.at_css('a[href="/"]')).not_to be_nil
    expect(header.at_css('a[href="/supporting_documents"]')).not_to be_nil
    expect(header.at_css('a[href="/setup"]')).not_to be_nil
    sair = header.css('button[type="submit"]').find { |button| button.text.strip == "Sair" }
    expect(sair).not_to be_nil
  end

  it "submitter header omits Configuracao and /setup" do
    account, organization = plant_submitter(organization_name: "ONG Norte")
    sign_in_as(account, organization: organization)

    get "/"

    expect(response).to have_http_status(:ok)
    header = Nokogiri::HTML(response.body).at_css("header")
    expect(header).not_to be_nil
    expect(header.at_css('a[href="/setup"]')).to be_nil
    expect(response.body).not_to include("Configuração")
  end
end
