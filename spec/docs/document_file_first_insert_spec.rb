require "rails_helper"

RSpec.describe "Document file-first insert sources" do
  it "visual-identity documents file-first proof square xor edit without XML" do
    text = Rails.root.join(".specs/features/visual-identity/design.md").read
    section = text.split("### `documents`", 2).last.split("## Responsive", 2).first

    expect(section).to include("proof square is the only file control")
    expect(section).to include("Limpar")
    expect(section).to include("Arquivo [Foto|XML locked]")
    expect(section).to include("Identificando o arquivo…")
    expect(section).to include("has no XML file control")
    expect(section).to include("Envie a foto ou o XML")
  end
end
