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
      expect(page).to have_button("Remover")
      expect(page.evaluate_script("document.documentElement.scrollWidth")).to be <= 390
    end
  end
end
