require "rails_helper"

RSpec.describe "Organization desk select", type: :request do
  it "Meses list omits Excluir and omits month-page links" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    Month.open(organization: organization, year_month: "2026-11")

    get "/"

    index = page_doc(response.body).at_css('[data-desk="index"]')
    expect(index.text).not_to include("Excluir")
    expect(index.css("a").map { |link| link["href"] }).not_to include("/months/2026-11")
  end

  it "people pin sits outside the Meses scroll" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/"

    index = page_doc(response.body).at_css('[data-desk="index"]')
    scroll = index.at_css(".desk-index-scroll")
    pin = index.at_css(".desk-index-pin")
    expect(scroll.text).to include("Meses")
    expect(pin.text).to include("Coordenadores e submitters")
    expect(scroll.css(".desk-index-pin")).to be_empty
    expect(index.inner_html.index("desk-index-scroll")).to be < index.inner_html.index("desk-index-pin")
  end

  it "people pin says 3 coordenadores 2 submitters and 1 falhou envio without convite" do
    account, organization = plant_pin_people
    sign_in_as(account, organization: organization)

    get "/"

    pin = page_doc(response.body).at_css(".desk-index-pin")
    expect(pin.text).to include("3 coordenadores · 2 submitters")
    fail_bit = pin.at_css(".text-margem")
    expect(fail_bit.text.strip).to eq("1 falhou envio")
    expect(pin.text.downcase).not_to include("convite")
  end

  it "people pin says 1 coordenador 1 submitter without falhou envio" do
    account, organization = plant_coordinator
    plant_submitter(organization: organization)
    sign_in_as(account, organization: organization)

    get "/"

    pin = page_doc(response.body).at_css(".desk-index-pin")
    expect(pin.text).to include("1 coordenador · 1 submitter")
    expect(pin.text).not_to include("falhou envio")
  end

  it "Meses row for 2026-10 is GET year_month 2026-10" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    Month.open(organization: organization, year_month: "2026-10")

    get "/"

    row = rows(response.body, "month").first
    expect(row.at_css("a")["href"]).to eq("/?year_month=2026-10")
  end

  it "selected never-sent 2026-11 right h1 Continuar and Excluir" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization, year_month: "2026-11")

    get "/?year_month=2026-11"

    in_work = page_doc(response.body).at_css('[data-desk="in-work"]')
    expect(in_work.at_css("h1").text.strip).to eq("novembro de 2026")
    expect(in_work.text).to include("2026-11")
    continuar = in_work.css("a").find { |link| link.text.strip == "Continuar" }
    expect(continuar["href"]).to eq("/months/2026-11")
    form = month_delete_form(in_work, "2026-11")
    expect(form["data-turbo-confirm"]).to eq("Excluir este fechamento?")
    button = form.at_css('button, input[type="submit"]')
    expect(button.text).to include("Excluir")
    expect(button["class"]).to include("ds-btn-secondary")
    expect(button["class"]).to include("ds-btn-danger")
  end

  it "selected never-sent Excluir is DELETE with turbo confirm" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    Month.open(organization: organization, year_month: "2026-11")

    get "/"

    form = month_delete_form(page_doc(response.body).at_css('[data-desk="in-work"]'), "2026-11")
    expect(form["action"]).to eq("/months/2026-11")
    expect(form.at_css('input[name="_method"][value="delete"]')).to be_present
    expect(form["data-turbo-confirm"]).to eq("Excluir este fechamento?")
  end

  it "closed selected month omits Excluir" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, _statement = plant_month(organization, year_month: "2026-10")
    month.update!(closed: true)

    get "/?year_month=2026-10"

    in_work = page_doc(response.body).at_css('[data-desk="in-work"]')
    expect(in_work.text).not_to include("Excluir")
    expect(month_delete_form(in_work, "2026-10")).to be_nil
  end

  it "closed selected month stamps Mes fechado and Continuar still links" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    month, _statement = plant_month(organization, year_month: "2026-10")
    month.update!(closed: true)

    get "/?year_month=2026-10"

    in_work = page_doc(response.body).at_css('[data-desk="in-work"]')
    expect(in_work.at_css(".stamp-closed").text.strip).to eq("Mês fechado")
    continuar = in_work.css("a").find { |link| link.text.strip == "Continuar" }
    expect(continuar["href"]).to eq("/months/2026-10")
  end

  it "selected month says 2 pagamentos com documento faltante in margem" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    _month, statement = plant_month(organization, year_month: "2026-11")
    2.times { |i| plant_payment(statement, 1000 + i) }

    get "/?year_month=2026-11"

    in_work = page_doc(response.body).at_css('[data-desk="in-work"]')
    sentences = in_work.css('[data-desk="missing"]')
    expect(sentences.size).to eq(1)
    expect(sentences.first.text.strip).to eq("2 pagamentos com documento faltante.")
    expect(sentences.first["class"]).to include("text-margem")
  end

  it "absent year_month selects the in-work open month" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization, year_month: "2026-10")
    closed = Month.open(organization: organization, year_month: "2026-11")
    closed.update!(closed: true)

    get "/"

    in_work = page_doc(response.body).at_css('[data-desk="in-work"]')
    expect(in_work.at_css("h1").text.strip).to eq("outubro de 2026")
  end

  it "empty year_month selects the in-work open month" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization, year_month: "2026-10")

    get "/", params: { year_month: "" }

    in_work = page_doc(response.body).at_css('[data-desk="in-work"]')
    expect(in_work.at_css("h1").text.strip).to eq("outubro de 2026")
  end

  it "unknown year_month selects the in-work open month" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization, year_month: "2026-10")

    get "/?year_month=2020-01"

    in_work = page_doc(response.body).at_css('[data-desk="in-work"]')
    expect(in_work.at_css("h1").text.strip).to eq("outubro de 2026")
  end

  it "Meses row from people desk fills the month desk" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    plant_month(organization, year_month: "2026-10")

    get "/?desk=people"

    row = rows(response.body, "month").first
    expect(row.at_css("a")["href"]).to eq("/?year_month=2026-10")
    expect(page_doc(response.body).at_css(".desk-index-pin a")["aria-current"]).to eq("true")

    get "/?year_month=2026-10"

    in_work = page_doc(response.body).at_css('[data-desk="in-work"]')
    expect(in_work.at_css("h1").text.strip).to eq("outubro de 2026")
    expect(page_doc(response.body).at_css(".desk-index-pin a")["aria-current"]).to be_nil
  end

  it "people pin is GET desk people" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/"

    pin = page_doc(response.body).at_css(".desk-index-pin a")
    expect(pin.text).to include("Coordenadores e submitters")
    expect(pin["href"]).to eq("/?desk=people")
  end

  it "people desk pin is aria-current and no Meses row is" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    Month.open(organization: organization, year_month: "2026-11")

    get "/?desk=people"

    expect(page_doc(response.body).at_css(".desk-index-pin a")["aria-current"]).to eq("true")
    expect(rows(response.body, "month").any? { |row| row.at_css("[aria-current]") }).to eq(false)
  end

  it "people book heading invite form Coordenadores then Submitters" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/?desk=people"

    in_work = page_doc(response.body).at_css('[data-desk="in-work"]')
    expect(in_work.at_css("h1").text.strip).to eq("Coordenadores e submitters")
    form = in_work.at_css("form")
    expect(in_work.inner_html.index("<h1")).to be < in_work.inner_html.index(form.to_html)
    expect(form.at_css("#invite-email")["placeholder"]).to eq("E-mail")
    options = form.css("#invite-kind option").map { |option| [ option.text.strip, option["value"] ] }
    expect(options).to eq([ [ "Coordenador", "Coordenador" ], [ "Submitter", "Submitter" ] ])
    expect(form.at_css('#invite-kind option[selected]')["value"]).to eq("Coordenador")
    expect(form.at_css('input[type="submit"][value="Convidar"]')).to be_present
    headings = in_work.css("h2").map { |h2| h2.text.strip }
    expect(headings.index("Coordenadores")).to be < headings.index("Submitters")
    coord_heading = in_work.css("h2").find { |h2| h2.text.strip == "Coordenadores" }
    expect(in_work.inner_html.index(form.to_html)).to be < in_work.inner_html.index(coord_heading.to_html)
  end

  it "people book meta is 5 pessoas 2 convites 1 falhou envio" do
    account, organization = plant_pin_people
    sign_in_as(account, organization: organization)

    get "/?desk=people"

    in_work = page_doc(response.body).at_css('[data-desk="in-work"]')
    expect(in_work.at_css("h1").next_element.text.strip).to eq("5 pessoas · 2 convites · 1 falhou envio")
  end

  it "people book lists standing then pending in insertion order" do
    account, organization = plant_coordinator(email: "first@exemplo.org")
    second = Account.create!(email: "second@exemplo.org", google_uid: "uid-second")
    Access.create!(account: second, organization: organization, kind: :coordinator)
    Invite.create!(organization: organization, email: "later-coord@exemplo.org", kind: :coordinator)
    Invite.create!(organization: organization, email: "early-coord@exemplo.org", kind: :coordinator)
    plant_submitter(email: "first-sub@exemplo.org", organization: organization)
    plant_submitter(email: "second-sub@exemplo.org", organization: organization)
    Invite.create!(organization: organization, email: "later-sub@exemplo.org", kind: :submitter)
    Invite.create!(organization: organization, email: "early-sub@exemplo.org", kind: :submitter)
    sign_in_as(account, organization: organization)

    get "/?desk=people"

    coord = people_section(response.body, "Coordenadores").css("ul li").map { |li| li.text }
    expect(coord[0]).to include("first@exemplo.org")
    expect(coord[0]).to include("Principal")
    expect(coord[0]).not_to include("Revogar")
    expect(coord[1]).to include("second@exemplo.org")
    expect(coord[2]).to include("later-coord@exemplo.org")
    expect(coord[3]).to include("early-coord@exemplo.org")
    subs = people_section(response.body, "Submitters").css("ul li").map { |li| li.text }
    expect(subs[0]).to include("first-sub@exemplo.org")
    expect(subs[1]).to include("second-sub@exemplo.org")
    expect(subs[2]).to include("later-sub@exemplo.org")
    expect(subs[3]).to include("early-sub@exemplo.org")
  end

  it "pending invite rows say Convite enviado or falhou envio do e-mail" do
    account, organization = plant_coordinator
    Invite.create!(organization: organization, email: "ok@exemplo.org", kind: :coordinator, last_delivery: :sent)
    Invite.create!(organization: organization, email: "fail@exemplo.org", kind: :submitter, last_delivery: :failed)
    sign_in_as(account, organization: organization)

    get "/?desk=people"

    sent = pending_invite_item(response.body, "ok@exemplo.org")
    failed = pending_invite_item(response.body, "fail@exemplo.org")
    expect(sent.text).to include("Convite · enviado")
    expect(sent.css("button").map { |button| button.text.strip }).to include("Reenviar e-mail", "Cancelar")
    expect(failed.text).to include("Convite · falhou envio do e-mail")
    expect(failed.at_css(".text-margem").text).to include("Convite · falhou envio do e-mail")
    expect(failed.css("button").map { |button| button.text.strip }).to include("Reenviar e-mail", "Cancelar")
  end

  it "empty people book says Nenhum coordenador and Nenhum submitter" do
    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)

    get "/?desk=people"

    expect(people_section(response.body, "Submitters").text).to include("Nenhum submitter")
    html = ApplicationController.render(
      partial: "organizations/people_book",
      assigns: {
        organization: organization,
        coordinator_accesses: [],
        submitter_accesses: [],
        coordinator_invites: [],
        submitter_invites: [],
        invites: [],
        failed_invite_count: 0
      }
    )
    expect(html).to include("Nenhum coordenador")
    expect(html).to include("Nenhum submitter")
  end

  it "submitter home ignores year_month and desk" do
    account, organization = plant_submitter
    sign_in_as(account, organization: organization)
    Month.open(organization: organization, year_month: "2026-11")

    get "/?year_month=2026-11&desk=people"

    doc = page_doc(response.body)
    expect(doc.at_css("h1").text.strip).to eq("Início")
    expect(response.body).not_to include("Coordenadores e submitters")
    expect(response.body).not_to include("Continuar")
    expect(response.body).not_to include("Abrir mês")
  end

  it "submitter one-organization home omits org listbox" do
    account, organization = plant_submitter(organization_name: "ONG Norte")
    sign_in_as(account, organization: organization)

    get "/"

    doc = page_doc(response.body)
    expect(doc.at_css('[aria-haspopup="listbox"]')).to be_nil
    expect(doc.at_css('[role="group"][aria-label="Organização"]')).to be_nil
    expect(doc.at_css("header").text).to include("ONG Norte")
  end

  def plant_pin_people
    account, organization = plant_coordinator(email: "one@exemplo.org")
    2.times do |i|
      person = Account.create!(email: "coord-#{i}@exemplo.org", google_uid: "uid-coord-#{i}")
      Access.create!(account: person, organization: organization, kind: :coordinator)
    end
    2.times do |i|
      plant_submitter(email: "sub-#{i}@exemplo.org", organization: organization)
    end
    Invite.create!(organization: organization, email: "pending@exemplo.org", kind: :coordinator, last_delivery: :sent)
    Invite.create!(organization: organization, email: "failed@exemplo.org", kind: :submitter, last_delivery: :failed)
    [ account, organization ]
  end

  def month_delete_form(row, year_month)
    row.css("form").find do |form|
      form["action"] == "/months/#{year_month}" && form.at_css('input[name="_method"][value="delete"]')
    end
  end

  def people_section(body, heading)
    node = page_doc(body).css("h2").find { |h2| h2.text.strip == heading }
    node.parent
  end
end
