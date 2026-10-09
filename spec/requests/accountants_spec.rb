require "rails_helper"

RSpec.describe "Accountants", type: :request do
  it "PATCH accountant with masked CNPJ stores digits only" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    patch "/accountant", params: {
      presentation_name: "Ana Contábil",
      tax_id: "11.222.333/0001-81",
      legal_name: "Contábil LTDA",
      pix_key: "chave-pix",
      destination_email: "ana@example.com"
    }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/setup")
    expect(organization.reload.accountant_tax_id).to eq("11222333000181")
  end

  it "PATCH /accountant from cadastro persists Ana and toasts Pronto" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    patch "/accountant", params: { presentation_name: "Ana" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/setup")
    expect(organization.reload.accountant_presentation_name).to eq("Ana")

    get "/setup"
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_node(response.body).text).to include("Pronto.")
  end

  it "PATCH /accountant from Editar 302s to leitura and toasts Pronto" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    persist_standing_accountant(organization)

    patch "/accountant", params: {
      presentation_name: "Ana Contábil",
      tax_id: "11222333000181",
      legal_name: "Contábil LTDA",
      pix_key: "chave-pix",
      destination_email: "ana@example.com"
    }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/setup")
    expect(organization.reload.accountant_tax_id).to eq("11222333000181")

    get "/setup"
    expect_accountant_leitura_cnpj_row(response.body)
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_node(response.body).text).to include("Pronto.")
  end

  it "PATCH /accountant 422 after standing name stays writable" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    organization.update_accountant(presentation_name: "Ana")
    tax_id_before = organization.reload.accountant_tax_id

    patch "/accountant", params: { presentation_name: "Ana", tax_id: "11222333000181" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(organization.reload.accountant_tax_id).to eq(tax_id_before)
    expect(error_notice_text(response.body)).to eq("Informe a razão social")
    form = accountant_form(response.body)
    expect(form.at_css('input[type="submit"][value="Salvar contador"]')).to be_present
    accountant_input_ids.each do |id|
      expect(form.at_css("##{id}")["readonly"]).to be_nil
    end
  end

  it "PATCH /accountant clearing the name returns cadastro" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    persist_standing_accountant(organization)

    patch "/accountant", params: { presentation_name: "" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/setup")
    organization.reload
    expect(organization.accountant_presentation_name).to be_nil
    expect(organization.accountant_tax_id).to be_nil
    expect(organization.accountant_legal_name).to be_nil
    expect(organization.accountant_pix_key).to be_nil
    expect(organization.package_destination_email).to be_nil

    get "/setup"
    expect_accountant_cadastro(response.body)
  end

  it "PATCH /accountant persists presentation name and redirects" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    patch "/accountant", params: { presentation_name: "  Ana Contábil  " }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/setup")
    expect(organization.reload.accountant_presentation_name).to eq("Ana Contábil")

    get "/setup"
    expect(response.body).to include("Ana Contábil")
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_node(response.body).text).to include("Pronto.")
  end

  it "PATCH /accountant persists CNPJ digits and razao social" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    patch "/accountant", params: {
      presentation_name: "Ana",
      tax_id: "11.222.333/0001-81",
      legal_name: "Contábil LTDA"
    }

    expect(response).to have_http_status(:found)
    expect(organization.reload.accountant_tax_id).to eq("11222333000181")
    expect(organization.accountant_legal_name).to eq("Contábil LTDA")
  end

  it "PATCH /accountant persists CPF digits and no razao social" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    patch "/accountant", params: { presentation_name: "Ana", tax_id: "390.533.447-05" }

    expect(response).to have_http_status(:found)
    expect(organization.reload.accountant_tax_id).to eq("39053344705")
    expect(organization.accountant_legal_name).to be_nil
  end

  it "PATCH /accountant persists normalized destination email" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    patch "/accountant", params: { presentation_name: "Ana", destination_email: "Coord@Example.COM" }

    expect(response).to have_http_status(:found)
    expect(organization.reload.package_destination_email).to eq("coord@example.com")
  end

  it "PATCH /accountant persists PIX of 1 and 77 characters" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    patch "/accountant", params: { presentation_name: "Ana", pix_key: "x" }
    expect(response).to have_http_status(:found)
    expect(organization.reload.accountant_pix_key).to eq("x")

    seventy_seven = "p" * 77
    patch "/accountant", params: { presentation_name: "Ana", pix_key: seventy_seven }
    expect(response).to have_http_status(:found)
    expect(organization.reload.accountant_pix_key).to eq(seventy_seven)
  end

  it "PATCH /accountant blank optional fields clears them" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    organization.update_accountant(
      presentation_name: "Ana",
      tax_id: "11222333000181",
      legal_name: "Contábil LTDA",
      pix_key: "chave",
      destination_email: "ana@example.com"
    )

    patch "/accountant", params: { presentation_name: "Ana" }

    expect(response).to have_http_status(:found)
    organization.reload
    expect(organization.accountant_tax_id).to be_nil
    expect(organization.accountant_legal_name).to be_nil
    expect(organization.accountant_pix_key).to be_nil
    expect(organization.package_destination_email).to be_nil
  end

  it "PATCH /accountant without presentation name returns 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    patch "/accountant", params: { tax_id: "39053344705", pix_key: "x", destination_email: "ana@example.com" }

    expect(response).to have_http_status(:unprocessable_content)
    organization.reload
    expect(organization.accountant_tax_id).to be_nil
    expect(organization.accountant_pix_key).to be_nil
    expect(organization.package_destination_email).to be_nil
    expect(toast_node(response.body)).to be_nil
  end

  it "PATCH /accountant rejected tax ids return 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    [ "1234567890", "39053344700", "11222333000180" ].each do |tax_id|
      patch "/accountant", params: { presentation_name: "Ana", tax_id: tax_id }
      expect(response).to have_http_status(:unprocessable_content)
      expect(organization.reload.accountant_tax_id).to be_nil
    end
  end

  it "PATCH /accountant CNPJ without razao social returns 422 Informe a razao social" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    patch "/accountant", params: { presentation_name: "Ana", tax_id: "11222333000181" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_notice_text(response.body)).to eq("Informe a razão social")
    expect(organization.reload.accountant_tax_id).to be_nil
  end

  it "PATCH /accountant CPF with razao social returns 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    patch "/accountant", params: {
      presentation_name: "Ana",
      tax_id: "39053344705",
      legal_name: "Não deveria"
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(organization.reload.accountant_tax_id).to be_nil
  end

  it "PATCH /accountant invalid destination returns 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    organization.update_accountant(presentation_name: "Ana", destination_email: "ana@example.com")

    patch "/accountant", params: { presentation_name: "Ana", destination_email: "not-an-email" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(organization.reload.package_destination_email).to eq("ana@example.com")
  end

  it "unauthenticated PATCH /accountant responds 302 to /login" do
    expect do
      patch "/accountant", params: { presentation_name: "Ana" }
    end.not_to(change { Organization.where.not(accountant_presentation_name: nil).count })

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "submitter PATCH /accountant persists no name and responds 404" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    patch "/accountant", params: { presentation_name: "Ana Contábil" }

    expect(response).to have_http_status(:not_found)
    expect(organization.reload.accountant_presentation_name).to be_nil
  end

  it "clearing PIX and tax id omits Sugestao de excecao" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    organization.update_accountant(presentation_name: "Ana Contadora", pix_key: "chave-pix", tax_id: "39053344705")
    _month, statement = plant_month(organization)
    plant_payment(statement, 22000, history: "Pix enviado chave-pix")

    patch "/accountant", params: { presentation_name: "Ana Contadora" }

    get "/months/2026-05"
    status = payment_status_html(response.body, history: "Pix enviado chave-pix")
    expect(status).not_to include("Sugestão de exceção")
  end
end
