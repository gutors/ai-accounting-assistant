require "rails_helper"

RSpec.describe "Focus", type: :request do
  it "POST /focus to an Access organization redirects" do
    account, org_a = plant_coordinator(email: "coord@example.com", organization_name: "ONG Norte")
    org_b = Organization.create!(name: "ONG Sul")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    sign_in_as(account, organization: org_a)

    post "/focus", params: { organization_id: org_b.id }

    expect(session[:organization_id]).to eq(org_b.id)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
    follow_redirect!
    expect(response.body).to include("ONG Sul")
  end

  it "focused organization button carries aria-current" do
    account, org_a = plant_coordinator(email: "coord@example.com", organization_name: "ONG Norte")
    org_b = Organization.create!(name: "ONG Sul")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    sign_in_as(account, organization: org_a)

    get "/"

    buttons = page_doc(response.body).css('nav[aria-label="Organizações"] button')
    norte = buttons.find { |button| button.text.strip == "ONG Norte" }
    sul = buttons.find { |button| button.text.strip == "ONG Sul" }
    expect(norte["aria-current"]).to eq("true")
    expect(sul.has_attribute?("aria-current")).to eq(false)
  end

  it "POST /focus without Access returns 404" do
    account, org_a = plant_coordinator(email: "coord@example.com", organization_name: "ONG Norte")
    outsider = Organization.create!(name: "ONG Outra")
    sign_in_as(account, organization: org_a)

    post "/focus", params: { organization_id: outsider.id }

    expect(response).to have_http_status(:not_found)
    expect(session[:organization_id]).to eq(org_a.id)
  end

  it "submitter POST /focus to an Access organization redirects" do
    account, org_a = plant_submitter(email: "sub@example.com", organization_name: "ONG Norte")
    org_b = Organization.create!(name: "ONG Sul")
    Access.create!(account: account, organization: org_b, kind: :submitter)
    sign_in_as(account, organization: org_a)

    post "/focus", params: { organization_id: org_b.id }

    expect(session[:organization_id]).to eq(org_b.id)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
    follow_redirect!
    expect(response.body).to include("ONG Sul")
  end

  it "submitter POST /focus without Access returns 404" do
    account, org_a = plant_submitter(email: "sub@example.com", organization_name: "ONG Norte")
    outsider = Organization.create!(name: "ONG Outra")
    sign_in_as(account, organization: org_a)

    post "/focus", params: { organization_id: outsider.id }

    expect(response).to have_http_status(:not_found)
    expect(session[:organization_id]).to eq(org_a.id)
  end
end
