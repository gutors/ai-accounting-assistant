require "rails_helper"

RSpec.describe "Setup configuration polish sources" do
  it "visual-identity setup and month record configuration polish" do
    design = Rails.root.join(".specs/features/visual-identity/design.md").read
    setup = design.split("### `setup` — `GET /setup`", 2).last.split("### `month` —", 2).first
    month = design.split("### `month` — `GET /months/:year_month`", 2).last.split("### `documents` —", 2).first

    expect(setup).to include("text-ink-soft")
    expect(setup).to include("font-medium")
    expect(setup).to include("tax-id-mask")
    expect(setup).to include("Ativa")
    expect(setup).to include("Inativa")
    expect(setup).to include("<details>")
    expect(setup).to include("Adicionar conta")
    expect(setup).to include("open on edit or bank 422")
    expect(setup).to include("Adicionar tipo extra")
    expect(setup).to include("Ativo")
    expect(setup).to include("Inativo")
    expect(setup).to include("Desativar")
    expect(setup).to include("Ativar")
    expect(setup).to include("no Excluir")

    expect(month).to include("Marcar tarifa")
    expect(month).to include("Marcar honorário")
    expect(month).to include("inactive")
  end
end
