require "rails_helper"

RSpec.describe "Document insert form sources" do
  it "visual-identity documents insert defaults date and hides Recibo chave XML" do
    text = Rails.root.join(".specs/features/visual-identity/design.md").read
    section = text.split("### `documents`", 2).last.split("## Responsive", 2).first

    expect(section).to include("Chave de acesso (opcional)")
    expect(section).to include("Observação (opcional)")
    expect(section).to include("two columns from 768px")
    expect(section).to include("the insert form is the first section")
    expect(section).to include("proof square is the only file control")
    expect(section).to include("hidden when Tipo is Recibo")
  end
end
