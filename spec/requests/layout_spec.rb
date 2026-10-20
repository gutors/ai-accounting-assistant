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
    expect(header.text).to include("Fechamento Mensal - ONG Norte")
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

  it "administrator coordinator header links Administracao after Configuracao" do
    account, organization = plant_coordinator(
      email: "seller@example.com",
      organization_name: "ONG Norte",
      google_uid: "uid-seller"
    )
    with_env("ADMINISTRATOR_EMAIL" => "seller@example.com") do
      sign_in_as(account, organization: organization)
      get "/"
    end

    expect(response).to have_http_status(:ok)
    header = Nokogiri::HTML(response.body).at_css("header")
    links = header.css("nav a").map { |link| [ link.text.strip, link["href"] ] }
    expect(links).to eq([
      [ "Início", "/" ],
      [ "Documentos", "/supporting_documents" ],
      [ "Configuração", "/setup" ],
      [ "Administração", "/administration" ]
    ])
    admin = header.at_css('a[href="/administration"]')
    expect(admin["class"]).to include("text-ink")
    expect(admin.ancestors("[class*='flex-wrap']")).not_to be_empty
    sair = header.css("button").select { |button| button.text.strip == "Sair" }
    expect(sair.size).to eq(1)
  end

  it "coordinator who is not the administrator has no Administracao link" do
    account, organization = plant_coordinator(email: "coordenador@exemplo.org", organization_name: "ONG Norte")
    with_env("ADMINISTRATOR_EMAIL" => "seller@example.com") do
      sign_in_as(account, organization: organization)
      get "/"
    end

    expect(response).to have_http_status(:ok)
    header = Nokogiri::HTML(response.body).at_css("header")
    expect(header.at_css('a[href="/"]')).not_to be_nil
    expect(header.at_css('a[href="/supporting_documents"]')).not_to be_nil
    expect(header.at_css('a[href="/setup"]')).not_to be_nil
    expect(header.at_css('a[href="/administration"]')).to be_nil
    expect(header.css("button").map { |button| button.text.strip }).to include("Sair")
  end

  it "administrator submitter header links Administracao after Documentos" do
    account, organization = plant_submitter(
      email: "seller@example.com",
      organization_name: "ONG Norte",
      google_uid: "uid-seller"
    )
    with_env("ADMINISTRATOR_EMAIL" => "seller@example.com") do
      sign_in_as(account, organization: organization)
      get "/"
    end

    expect(response).to have_http_status(:ok)
    header = Nokogiri::HTML(response.body).at_css("header")
    links = header.css("nav a").map { |link| [ link.text.strip, link["href"] ] }
    expect(links).to eq([
      [ "Início", "/" ],
      [ "Documentos", "/supporting_documents" ],
      [ "Administração", "/administration" ]
    ])
    expect(header.text).not_to include("Configuração")
    expect(header.css("button").map { |button| button.text.strip }).to include("Sair")
  end

  it "wait overlay sits after main and stays hidden" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/"

    expect(response).to have_http_status(:ok)
    doc = page_doc(response.body)
    expect(doc.at_css("body")["data-controller"]).to eq("wait")
    header = doc.at_css("header")
    expect(header["class"]).to include("relative")
    expect(header.at_css(".wait-rule")).not_to be_nil
    wait = doc.at_css("#wait")
    expect(wait["hidden"]).not_to be_nil
    expect(wait["aria-hidden"]).to eq("true")
    expect(wait["role"]).to eq("status")
    expect(wait["aria-busy"]).to eq("false")
    expect(wait["data-wait-target"]).to eq("panel")
    expect(wait.at_css(".wait-veil")).not_to be_nil
    copy = wait.at_css("[data-wait-target='copy']")
    expect(copy.text.strip).to eq("Aguarde")
    expect(doc.at_css("main").next_element).to eq(wait)
  end

  it "GET / with empty flash has no toast" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    session[:invite_mail_failed] = true

    get "/"

    expect(response).to have_http_status(:ok)
    expect(page_doc(response.body).at_css("#toast-host")).not_to be_nil
    expect(toast_node(response.body)).to be_nil
    mail_failure = "O convite foi gravado, mas o e-mail não saiu."
    expect(response.body).not_to include(mail_failure)
    notice_with_mail = page_doc(response.body).css("[data-notice='error']").find { |node|
      node.text.include?(mail_failure)
    }
    expect(notice_with_mail).to be_nil
    h1 = page_doc(response.body).at_css("h1")
    expect(h1.text.strip).to eq("Início")
    expect(h1.parent.at_css("section").text).not_to include(mail_failure)
  end

  it "success toast sits after header before main" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    post "/months", params: { year_month: "2026-05" }
    follow_redirect!

    doc = page_doc(response.body)
    toasts = doc.css("[data-toast]")
    expect(toasts.size).to eq(1)
    toast = toasts.first
    expect(toast["data-toast-kind"]).to eq("success")
    expect(toast["role"]).to eq("status")
    expect(toast["data-toast-timeout-ms"]).to eq("5000")
    expect(toast.text).to include("Pronto.")
    expect(toast.at_css("button").text.strip).to eq("Fechar")
    expect(toast["class"]).to include("bg-caixa")
    expect(toast["class"]).to include("text-white")
    expect(toast["data-notice"]).to be_nil
    expect(toast.at_css("[data-notice]")).to be_nil
    host = doc.at_css("#toast-host")
    expect(host).not_to be_nil
    expect(doc.at_css("header").next_element).to eq(host)
    expect(host.at_css("[data-toast]")).to eq(toast)
    expect(host.next_element.name).to eq("main")
  end

  it "error toast sits after header before main" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    ActionMailer::Base.register_interceptor(CoordinatorInviteDeliveryFail)
    CoordinatorInviteDeliveryFail.raise_now = true
    begin
      post "/coordinator_invites", params: { email: "guest@example.com" }
      follow_redirect!

      doc = page_doc(response.body)
      toasts = doc.css("[data-toast]")
      expect(toasts.size).to eq(1)
      toast = toasts.first
      expect(toast["data-toast-kind"]).to eq("error")
      expect(toast["role"]).to eq("alert")
      expect(toast["data-toast-timeout-ms"]).to eq("5000")
      expect(toast.text).to include("O convite foi gravado, mas o e-mail não saiu.")
      expect(toast.at_css("button").text.strip).to eq("Fechar")
      expect(toast["class"]).to include("text-margem")
      expect(toast["class"]).to include("border-l-[3px]")
      expect(toast["class"]).to include("border-margem")
      host = doc.at_css("#toast-host")
      expect(host).not_to be_nil
      expect(doc.at_css("header").next_element).to eq(host)
      expect(host.at_css("[data-toast]")).to eq(toast)
      expect(host.next_element.name).to eq("main")
    ensure
      CoordinatorInviteDeliveryFail.raise_now = false
      ActionMailer::Base.unregister_interceptor(CoordinatorInviteDeliveryFail)
    end
  end
end
