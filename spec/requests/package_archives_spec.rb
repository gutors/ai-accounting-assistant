require "rails_helper"

RSpec.describe "Package archives", type: :request do
  let(:folders_url) { "https://drive.google.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl" }

  it "PATCH /package_archive from cadastro persists folders URL and toasts Pronto" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    patch "/package_archive", params: { url: folders_url }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/setup")
    organization.reload
    expect(organization.package_archive_url).to eq(folders_url)
    expect(organization.package_archive_folder_id).to eq("15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl")

    get "/setup"
    expect_archive_leitura(response.body, url: folders_url)
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_node(response.body).text).to include("Pronto.")
  end

  it "PATCH /package_archive persists folder id from u/0 URL with query" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    url = "https://drive.google.com/drive/u/0/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl?usp=sharing"

    patch "/package_archive", params: { url: url }

    expect(response).to have_http_status(:found)
    expect(organization.reload.package_archive_folder_id).to eq("15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl")
  end

  it "PATCH /package_archive blank URL returns cadastro" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    organization.update_package_archive(folders_url)

    patch "/package_archive", params: { url: "" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/setup")
    organization.reload
    expect(organization.package_archive_url).to be_nil
    expect(organization.package_archive_folder_id).to be_nil

    get "/setup"
    expect_archive_cadastro(response.body)
  end

  it "PATCH /package_archive from Editar 302s to leitura and toasts Pronto" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    organization.update_package_archive(folders_url)
    new_url = "https://drive.google.com/drive/folders/1AbCdEfGhIjKlMnOpQrStUvWxYz123456"

    patch "/package_archive", params: { url: new_url }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/setup")
    organization.reload
    expect(organization.package_archive_url).to eq(new_url)
    expect(organization.package_archive_folder_id).to eq("1AbCdEfGhIjKlMnOpQrStUvWxYz123456")

    get "/setup"
    expect_archive_leitura(response.body, url: new_url)
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_node(response.body).text).to include("Pronto.")

    patch "/package_archive", params: { url: new_url }
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/setup")
    get "/setup"
    expect_archive_leitura(response.body, url: new_url)
  end

  it "PATCH /package_archive rejected folder URLs return 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    organization.update_package_archive(folders_url)

    [
      "http://drive.google.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl",
      "https://example.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl",
      "https://drive.google.com/drive/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl"
    ].each do |url|
      patch "/package_archive", params: { url: url }
      expect(response).to have_http_status(:unprocessable_content)
      organization.reload
      expect(organization.package_archive_url).to eq(folders_url)
      expect(organization.package_archive_folder_id).to eq("15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl")
    end
  end

  it "PATCH /package_archive 422 file URL stays Confirmar" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    organization.update_package_archive(folders_url)

    patch "/package_archive", params: { url: "https://drive.google.com/file/d/0B_NiLAzvehC9R2stRmQyM3ZiVjQ/view" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(organization.reload.package_archive_url).to eq(folders_url)
    expect(toast_node(response.body)).to be_nil
    expect_archive_edicao(response.body, url: folders_url)
  end

  it "PATCH /package_archive 422 during cadastro stays Salvar arquivo" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    patch "/package_archive", params: { url: "https://example.com/drive/folders/15uNXeRBIhVvZJIhL4yTw4IsStMhUaaxl" }

    expect(response).to have_http_status(:unprocessable_content)
    organization.reload
    expect(organization.package_archive_url).to be_nil
    expect(organization.package_archive_folder_id).to be_nil
    expect(toast_node(response.body)).to be_nil
    expect_archive_cadastro(response.body)
  end

  it "unauthenticated PATCH /package_archive responds 302 to /login" do
    patch "/package_archive", params: { url: folders_url }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
    expect(Organization.where.not(package_archive_url: nil).count).to eq(0)
  end

  it "submitter PATCH /package_archive persists no URL and responds 404" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    patch "/package_archive", params: { url: folders_url }

    expect(response).to have_http_status(:not_found)
    expect(organization.reload.package_archive_url).to be_nil
  end
end
