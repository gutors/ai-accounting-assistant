require "rails_helper"

RSpec.describe "Focus", type: :request do
  it "POST /focus names the organization in the toast" do
    account, org_a = plant_coordinator(email: "coord@example.com", organization_name: "ONG Norte")
    org_b = create_organization!(name: "ONG Sul")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    plant_month(org_b, year_month: "2026-05")
    sign_in_as(account, organization: org_a)

    get "/"
    sul_form = page_doc(response.body).css("form").find do |form|
      form["action"] == "/focus" && form.at_css("button")&.text&.strip == "ONG Sul"
    end
    expect(sul_form.at_css('input[name="organization_id"]')["value"]).to eq(org_b.id.to_s)

    post "/focus", params: { organization_id: sul_form.at_css('input[name="organization_id"]')["value"] }

    expect(session[:organization_id]).to eq(org_b.id)
    expect(response).to have_http_status(:found)
    expect(response).to redirect_to("/")
    follow_redirect!
    expect(toast_node(response.body)["data-toast-kind"]).to eq("success")
    expect(toast_message(response.body)).to eq("Agora em ONG Sul.")
    expect(page_doc(response.body).at_css("header").text).to include("ONG Sul")
    expect(page_doc(response.body).at_css('[data-desk="in-work"] h1').text.strip).to eq("maio de 2026")
    expect(page_doc(response.body).at_css('[data-desk="in-work"] h1').text).not_to include("Coordenadores e submitters")
  end

  it "two-organization header switcher names the focused org" do
    account, org_a = plant_coordinator(email: "coord@example.com", organization_name: "ONG Norte")
    org_b = create_organization!(name: "ONG Sul")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    sign_in_as(account, organization: org_a)

    get "/"

    button = page_doc(response.body).at_css('header [aria-haspopup="listbox"]')
    expect(button["aria-label"]).to eq("Organização: ONG Norte. Abrir lista")
    expect(button["aria-expanded"]).to eq("false")
    expect(button.text.strip).to eq("ONG Norte")
  end

  it "header list marks the focused organization aria-current" do
    account, org_a = plant_coordinator(email: "coord@example.com", organization_name: "ONG Norte")
    org_b = create_organization!(name: "ONG Sul")
    Access.create!(account: account, organization: org_b, kind: :coordinator)
    sign_in_as(account, organization: org_a)

    get "/"

    list = page_doc(response.body).at_css("#org-list")
    buttons = list.css("button")
    expect(buttons.map { |button| button.text.strip }).to contain_exactly("ONG Norte", "ONG Sul")
    norte = buttons.find { |button| button.text.strip == "ONG Norte" }
    sul = buttons.find { |button| button.text.strip == "ONG Sul" }
    expect(norte["aria-current"]).to eq("true")
    expect(sul.has_attribute?("aria-current")).to eq(false)
  end

  it "POST /focus without Access returns 404" do
    account, org_a = plant_coordinator(email: "coord@example.com", organization_name: "ONG Norte")
    outsider = create_organization!(name: "ONG Outra")
    sign_in_as(account, organization: org_a)

    post "/focus", params: { organization_id: outsider.id }

    expect(response).to have_http_status(:not_found)
    expect(session[:organization_id]).to eq(org_a.id)
  end

  it "submitter POST /focus to an Access organization redirects" do
    account, org_a = plant_submitter(email: "sub@example.com", organization_name: "ONG Norte")
    org_b = create_organization!(name: "ONG Sul")
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
    outsider = create_organization!(name: "ONG Outra")
    sign_in_as(account, organization: org_a)

    post "/focus", params: { organization_id: outsider.id }

    expect(response).to have_http_status(:not_found)
    expect(session[:organization_id]).to eq(org_a.id)
  end
end
