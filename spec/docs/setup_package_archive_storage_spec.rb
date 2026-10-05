require "rails_helper"

RSpec.describe "Setup package archive storage sources" do
  it "visual-identity setup archive is cadastro or labeled text" do
    text = Rails.root.join(".specs/features/visual-identity/design.md").read
    section = text.split("### `setup` — `GET /setup`", 2).last.split("### `month` —", 2).first
    without_google_drive_label = section.gsub("URL da pasta do Google Drive", "").gsub("Cole a URL da pasta do Google Drive", "")

    expect(section).to include("Armazenamento do pacote mensal")
    expect(section).to include("Cole a URL da pasta do Google Drive")
    expect(section).to include("URL da pasta do Google Drive")
    expect(section).to include("[Salvar arquivo]")
    expect(section).to include("font-medium")
    expect(section).to include("[Editar]")
    expect(section).to include("edit=package_archive")
    expect(section).to include("input#url")
    expect(section).to include("[Confirmar]")
    expect(section).to include("labeled")
    expect(section).to include("formatted CPF/CNPJ")
    expect(section).to include("edit=accountant")
    expect(section).to include("input chrome")
    expect(section).not_to include("Arquivo do pacote")
    expect(section).not_to include("always-writable")
    expect(section).not_to include("#81")
    expect(without_google_drive_label).not_to include("URL da pasta do Drive")
    expect(without_google_drive_label).not_to include("Cole a URL da pasta do Drive")
  end
end
