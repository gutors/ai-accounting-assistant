require "rails_helper"

RSpec.describe "Extra exception kinds", type: :request do
  it "POST /extra_exception_kinds persists Doacao and redirects" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    post "/extra_exception_kinds", params: { name: "Doação" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/setup")
    kind = organization.extra_exception_kinds.last
    expect(kind).to be_active
    expect(kind.name).to eq("Doação")

    get "/setup"
    expect(response.body).to include("Doação")
  end

  it "POST /extra_exception_kinds persists trimmed Doacao" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    post "/extra_exception_kinds", params: { name: "  Doação  " }

    expect(organization.extra_exception_kinds.last.name).to eq("Doação")
  end

  it "POST /extra_exception_kinds on A leaves B Doacao in place" do
    account, org_a = plant_coordinator(email: "a@example.com", organization_name: "A")
    org_b = create_organization!(name: "B")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    ExtraExceptionKind.create_for(organization: org_b, name: "Doação")
    sign_in_as(account, organization: org_a)

    post "/extra_exception_kinds", params: { name: "Doação" }

    expect(org_a.extra_exception_kinds.where(name: "Doação").count).to eq(1)
    expect(org_b.extra_exception_kinds.where(name: "Doação").count).to eq(1)
  end

  it "POST duplicate Doacao returns 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ExtraExceptionKind.create_for(organization: organization, name: "Doação")

    post "/extra_exception_kinds", params: { name: "Doação" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(organization.extra_exception_kinds.where(name: "Doação").count).to eq(1)
  end

  it "POST doacao when Doacao exists returns 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ExtraExceptionKind.create_for(organization: organization, name: "Doação")

    post "/extra_exception_kinds", params: { name: "doação" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(organization.extra_exception_kinds.count).to eq(1)
  end

  it "POST Tarifa bancaria returns 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    post "/extra_exception_kinds", params: { name: "Tarifa bancária" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(organization.extra_exception_kinds.count).to eq(0)
  end

  it "POST honorario do contador returns 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    post "/extra_exception_kinds", params: { name: "honorário do contador" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(organization.extra_exception_kinds.count).to eq(0)
  end

  it "POST blank name returns 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    post "/extra_exception_kinds", params: { name: "  " }

    expect(response).to have_http_status(:unprocessable_content)
    expect(organization.extra_exception_kinds.count).to eq(0)
  end

  it "unauthenticated POST /extra_exception_kinds responds 302 to /login" do
    expect do
      post "/extra_exception_kinds", params: { name: "Doação" }
    end.not_to change(ExtraExceptionKind, :count)

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/login")
  end

  it "PATCH name Outro leaves Doacao" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")

    patch "/extra_exception_kinds/#{kind.id}", params: { name: "Outro" }

    expect(kind.reload.name).to eq("Doação")
  end

  it "PATCH extra exception kind inactive keeps row and shows Desativado" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")

    patch "/extra_exception_kinds/#{kind.id}", params: { active: false }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/setup")
    expect(kind.reload).not_to be_active

    get "/setup"
    expect(response.body).to include("Doação")
    expect(response.body).to include("Desativado")
  end

  it "PATCH extra exception kind active omits Desativado on that row" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    kind.apply_active(false)

    patch "/extra_exception_kinds/#{kind.id}", params: { active: true }

    get "/setup"
    row = extra_kind_row(response.body, "Doação")
    expect(row).to include("Doação")
    expect(row).not_to include("Desativado")
  end

  it "DELETE unused Folha removes the row and redirects" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ExtraExceptionKind.create_for(organization: organization, name: "Folha")

    delete "/extra_exception_kinds/#{organization.extra_exception_kinds.find_by!(name: "Folha").id}"

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/setup")
    expect(organization.extra_exception_kinds.find_by(name: "Folha")).to be_nil

    get "/setup"
    expect(response.body).not_to include("Folha")
  end

  it "DELETE used Doacao returns 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    _month, statement = plant_month(organization)
    payment = plant_payment(statement, 22000)
    payment.update!(extra_exception_kind: kind)

    delete "/extra_exception_kinds/#{kind.id}"

    expect(response).to have_http_status(:unprocessable_content)
    expect(ExtraExceptionKind.find(kind.id)).to eq(kind)
  end

  it "POST Doacao while deactivated Doacao exists returns 422" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    kind.apply_active(false)

    post "/extra_exception_kinds", params: { name: "Doação" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(organization.extra_exception_kinds.count).to eq(1)
    expect(kind.reload).not_to be_active
  end

  it "DELETE extra exception kind of another organization returns 404" do
    account, organization = plant_coordinator(email: "a@example.com", organization_name: "A")
    other = create_organization!(name: "B")
    kind = ExtraExceptionKind.create_for(organization: other, name: "Doação")
    sign_in_as(account, organization: organization)

    delete "/extra_exception_kinds/#{kind.id}"

    expect(response).to have_http_status(:not_found)
    expect(ExtraExceptionKind.find(kind.id)).to eq(kind)
  end

  it "PATCH extra exception kind of another organization returns 404" do
    account, organization = plant_coordinator(email: "a@example.com", organization_name: "A")
    other = create_organization!(name: "B")
    kind = ExtraExceptionKind.create_for(organization: other, name: "Doação")
    sign_in_as(account, organization: organization)

    patch "/extra_exception_kinds/#{kind.id}", params: { active: false }

    expect(response).to have_http_status(:not_found)
    expect(kind.reload).to be_active
  end

  it "POST /extra_exception_kinds while month closed persists and redirects" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, _statement = plant_month(organization)
    month.update!(closed: true)

    post "/extra_exception_kinds", params: { name: "Doação" }

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/setup")
    expect(organization.extra_exception_kinds.find_by(name: "Doação")).to be_present
  end

  it "submitter POST /extra_exception_kinds persists none and responds 404" do
    _coord, organization = plant_coordinator
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    expect do
      post "/extra_exception_kinds", params: { name: "Doação" }
    end.not_to change(ExtraExceptionKind, :count)

    expect(response).to have_http_status(:not_found)
  end

  it "submitter PATCH extra exception kind returns 404" do
    _coord, organization = plant_coordinator
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    patch "/extra_exception_kinds/#{kind.id}", params: { active: false }

    expect(response).to have_http_status(:not_found)
    expect(kind.reload).to be_active
  end

  it "submitter DELETE extra exception kind returns 404" do
    _coord, organization = plant_coordinator
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Folha")
    submitter, _ = plant_submitter(organization: organization)
    sign_in_as(submitter, organization: organization)

    delete "/extra_exception_kinds/#{kind.id}"

    expect(response).to have_http_status(:not_found)
    expect(ExtraExceptionKind.find(kind.id)).to eq(kind)
  end

  it "extra exception kind row carries data-row hook" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    kind = ExtraExceptionKind.create_for(organization: organization, name: "Doação")

    get "/setup"

    kind_row = row(response.body, "extra-exception-kind", extra_exception_kind_id: kind.id)
    expect(kind_row).not_to be_nil
    expect(kind_row.text).to include("Doação")
  end

  def extra_kind_row(body, name)
    rows_html(body, "extra-exception-kind").find { |li| li.include?(name) }
  end
end
