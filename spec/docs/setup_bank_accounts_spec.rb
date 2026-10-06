require "rails_helper"

RSpec.describe "Setup bank account sources" do
  it "visual-identity setup bank accounts are four cells and one section form" do
    design = Rails.root.join(".specs/features/visual-identity/design.md").read
    section = design.split("### `setup` — `GET /setup`", 2).last.split("### `month` —", 2).first

    expect(section).not_to include("Coordenadas")
    expect(section).not_to include("<details><summary>Editar</summary>")
    expect(section).not_to include("▸ Editar")
    expect(section).to include("li[data-row=\"bank-account\"]")
    expect(section).to include("Agência/Conta Corrente")
    expect(section).to include("Adicionar conta")
    expect(section).to include("Salvar conta")
    expect(section).to include("Desativar")
    expect(section).to include("Reativar")
    expect(section).to include("edit=bank_account")
    expect(section.index("bank presentation name")).to be < section.index("agência/conta corrente")
    expect(section).to include("extrato-{slug}")
    expect(section).to include("one section form")

    c42 = Rails.root.join(".specs/features/visual-identity/checks.md").read[/^\*\*C42\*\*.+?(?=^\*\*C43\*\*)/m]
    expect(c42).not_to include("<details>")
    expect(c42).not_to include("<summary>")
    expect(c42).to include("Editar")
    expect(c42).to include("/setup")
    expect(c42).to include("Salvar conta")
  end
end
