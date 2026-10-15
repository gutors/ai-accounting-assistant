require "rails_helper"

RSpec.describe "Keep form on 422 sources" do
  it "visual-identity documents and setup keep form on 422" do
    text = Rails.root.join(".specs/features/visual-identity/design.md").read
    documents = text.split("### `documents`", 2).last.split("## Responsive", 2).first
    setup = text.split("### `setup` — `GET /setup`", 2).last.split("### `month` —", 2).first

    expect(documents).to include("Limpar")
    expect(documents).to include("Foto")
    expect(documents).to include("XML")
    expect(documents).to include("HTML 422 fallback")
    expect(documents).to include("Tipo")
    expect(documents).to include("Valor")
    expect(documents).to include("Data")
    expect(documents).to include("Favorecido")
    expect(documents).to include("Chave")
    expect(documents).to include("Observação")
    expect(documents).to include("the square's file input stays in the form")

    expect(setup).to include("Arquivo [Limpar]")
    expect(setup).to include("HTML `422` does not write Senha into the HTML")
  end
end
