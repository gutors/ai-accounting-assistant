require "rails_helper"
require "capybara/cuprite"

RSpec.describe "Administration screens", type: :system do
  before do
    driven_by :cuprite, screen_size: [ 1280, 900 ], options: {
      browser_options: { "no-sandbox": nil },
      process_timeout: 30,
      timeout: 15
    }
  end

  it "list, add, and edit stay within 390px without a form on the list" do
    norte = create_organization!(name: "ONG Norte")
    ana = Account.create!(email: "ana@exemplo.org")
    Access.create!(account: ana, organization: norte, kind: :coordinator)

    with_env("ADMINISTRATOR_EMAIL" => "seller@example.com", "MAIL_FROM" => "venda@example.com") do
      stub_google_oauth(email: "seller@example.com", uid: "uid-seller")
      visit "/auth/google_oauth2/callback"

      page.driver.resize(390, 844)
      visit "/administration"
      expect(page).to have_css("h1", text: "Administração")
      expect(page).to have_link("Adicionar organização", href: "/administration/new")
      expect(page).not_to have_field("Nome da organização")
      expect(page).not_to have_button("Remover")
      expect(page.evaluate_script("document.documentElement.scrollWidth")).to be <= 390

      visit "/administration/new"
      expect(page).to have_css("h1", text: "Adicionar organização")
      expect(page).to have_button("Continuar")
      expect(page.evaluate_script("document.documentElement.scrollWidth")).to be <= 390

      visit "/administration/#{norte.id}/edit"
      expect(page).to have_css("h1", text: "Editar organização")
      expect(page).to have_content("Nome da organização")
      expect(page).to have_content("E-mail do coordenador principal")
      expect(page).to have_button("Remover")
      expect(page.evaluate_script("document.documentElement.scrollWidth")).to be <= 390
    end
  end

  it "edit shows identity labels and keeps them after Corrigir nome and Corrigir" do
    zoe = Account.create!(email: "zoe@exemplo.org")
    norte = create_organization!(name: "ONG Norte", principal_coordinator_account: zoe)
    ana = Account.create!(email: "ana@exemplo.org")
    Access.create!(account: zoe, organization: norte, kind: :coordinator)
    Access.create!(account: ana, organization: norte, kind: :coordinator)

    with_env("ADMINISTRATOR_EMAIL" => "seller@example.com", "MAIL_FROM" => "venda@example.com") do
      stub_google_oauth(email: "seller@example.com", uid: "uid-seller")
      visit "/auth/google_oauth2/callback"
      visit "/administration/#{norte.id}/edit"

      expect(page).to have_css("h1", text: "Editar organização")
      expect(page).to have_content("Nome da organização")
      expect(page).to have_content("ONG Norte")
      expect(page).to have_content("E-mail do coordenador principal")
      expect(page).to have_content("zoe@exemplo.org")
      expect(page).to have_content("Outros coordenadores")
      expect(page).to have_content("ana@exemplo.org")

      click_button "Corrigir nome"
      expect(page).to have_field("Nome da organização", with: "ONG Norte")
      expect(page).to have_button("Continuar")
      expect(page).to have_content("E-mail do coordenador principal")
      expect(page).to have_content("zoe@exemplo.org")
      expect(page).to have_content("Outros coordenadores")
      expect(page).to have_content("ana@exemplo.org")
      expect(page).not_to have_button("Remover")

      click_button "Cancelar"
      click_button "Corrigir"
      expect(page).to have_content("Nome da organização")
      expect(page).to have_content("ONG Norte")
      expect(page).to have_field("E-mail do coordenador principal", with: "zoe@exemplo.org")
      expect(page).to have_content("Outros coordenadores")
      expect(page).to have_content("ana@exemplo.org")
      expect(page).not_to have_button("Corrigir")
    end
  end

  it "header keeps nav after the signed-in principal is replaced on the focused organization" do
    seller, sul = plant_coordinator(
      email: "seller@example.com",
      organization_name: "ONG Sul",
      google_uid: "uid-seller"
    )
    norte = create_organization!(name: "ONG Norte", principal_coordinator_account: seller)
    Access.create!(account: seller, organization: norte, kind: :coordinator)

    with_env("ADMINISTRATOR_EMAIL" => "seller@example.com", "MAIL_FROM" => "venda@example.com") do
      stub_google_oauth(email: "seller@example.com", uid: "uid-seller")
      visit "/auth/google_oauth2/callback"
      visit "/"
      click_button "ONG Norte"
      visit "/administration/#{norte.id}/edit"
      click_button "Corrigir"
      fill_in "E-mail do coordenador principal", with: "novo@exemplo.org"
      click_button "Continuar"
      click_button "Confirmar"

      expect(page).to have_css("h1", text: "Administração")
      expect(page).to have_css("header", text: "Fechamento Mensal - ONG Sul")
      expect(page).to have_link("Início", href: "/")
      expect(page).to have_link("Administração", href: "/administration")
      expect(page).to have_button("Sair")
    end
  end
end
