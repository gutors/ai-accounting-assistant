require "rails_helper"

RSpec.describe "Base document exceptions", type: :request do
  it "PATCH bank_fee inactive 302s Inativo and toasts Pronto" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    patch "/base_document_exceptions/bank_fee", params: { active: false }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/setup")
    organization.reload
    expect(organization.bank_fee_exception_active).to eq(false)
    expect(organization.accountant_fee_exception_active).to eq(true)
    expect(organization.extra_exception_kinds.count).to eq(0)

    get "/setup"
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_node(response.body).text).to include("Pronto.")
    row = base_exception_row(response.body, "Tarifa bancária")
    expect(row.text).to include("Inativo")
    expect(row.text).to include("Ativar")
    expect(row.text).not_to include("Desativar")
    expect(row.text).not_to include("Excluir")

    patch "/base_document_exceptions/bank_fee", params: { active: false }

    expect(response).to have_http_status(:found)
    expect(organization.reload.bank_fee_exception_active).to eq(false)
  end

  it "PATCH accountant_fee inactive 302s Honorario Inativo" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    organization.update!(bank_fee_exception_active: true)

    patch "/base_document_exceptions/accountant_fee", params: { active: false }

    expect(response).to have_http_status(:found)
    organization.reload
    expect(organization.accountant_fee_exception_active).to eq(false)
    expect(organization.bank_fee_exception_active).to eq(true)
    expect(organization.extra_exception_kinds.count).to eq(0)

    get "/setup"
    row = base_exception_row(response.body, "Honorário do contador")
    expect(row.text).to include("Inativo")
    expect(row.text).to include("Ativar")
    expect(row.text).not_to include("Excluir")
  end

  it "PATCH bank_fee active after inactive restores Ativo Desativar" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    organization.update!(bank_fee_exception_active: false)

    patch "/base_document_exceptions/bank_fee", params: { active: true }

    expect(organization.reload.bank_fee_exception_active).to eq(true)

    get "/setup"
    row = base_exception_row(response.body, "Tarifa bancária")
    expect(row.text).to include("Ativo")
    expect(row.text).to include("Desativar")
    expect(row.text).not_to include("Inativo")
    expect(row.text).not_to include("Excluir")
  end

  it "unauthenticated PATCH bank_fee 302s to login" do
    _account, organization = plant_coordinator
    expect(organization.bank_fee_exception_active).to eq(true)

    patch "/base_document_exceptions/bank_fee", params: { active: false }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
    expect(organization.reload.bank_fee_exception_active).to eq(true)
  end

  it "submitter PATCH bank_fee returns 404" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    patch "/base_document_exceptions/bank_fee", params: { active: false }

    expect(response).to have_http_status(:not_found)
    expect(organization.reload.bank_fee_exception_active).to eq(true)
  end

  it "PATCH not_a_kind returns 404" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    patch "/base_document_exceptions/not_a_kind", params: { active: false }

    expect(response).to have_http_status(:not_found)
    organization.reload
    expect(organization.bank_fee_exception_active).to eq(true)
    expect(organization.accountant_fee_exception_active).to eq(true)
  end

  it "PATCH bank_fee inactive inserts no ExtraExceptionKind" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    patch "/base_document_exceptions/bank_fee", params: { active: false }

    expect(organization.extra_exception_kinds.count).to eq(0)
  end
end
