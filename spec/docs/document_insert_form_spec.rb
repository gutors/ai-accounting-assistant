require "rails_helper"

RSpec.describe "Document insert form sources" do
  it "visual-identity documents insert defaults date and hides Recibo chave XML" do
    text = Rails.root.join(".specs/features/visual-identity/design.md").read
    section = text.split("### `documents`", 2).last.split("## Responsive", 2).first

    expect(section).to include("Chave de acesso (opcional)")
    expect(section).to include("Observação (opcional)")
    expect(section).to match(/Data \[today\]/)
    expect(section).to include("Recibo")
    expect(section).to include("hiding chave and XML")
    expect(section).to include("photo only")
  end
end
