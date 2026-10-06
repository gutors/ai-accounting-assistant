require "rails_helper"

RSpec.describe "Setup extra kinds justification sources" do
  it "visual-identity setup extras list fixed kinds and justification" do
    text = Rails.root.join(".specs/features/visual-identity/design.md").read
    section = text.split("### `setup` — `GET /setup`", 2).last.split("### `month` —", 2).first
    extras = section.split("Tipos extras de exceção", 2).last.split("Contador is cadastro", 2).first

    expect(extras.index("Tarifa bancária")).to be < extras.index("Honorário do contador")
    expect(extras).to include("Tarifa cobrada pelo banco; não há documento fiscal a anexar.")
    expect(extras).to include("Honorário do contador neste fechamento; isento de documento de suporte.")
    expect(extras).to include("Doação")
    expect(extras).to include("Doação pontual sem nota.")
    expect(extras).to include("Nome / Justificativa")
    expect(extras).to include("[Adicionar tipo extra]")
    expect(extras).not_to include("Nenhum tipo extra")
  end
end
