require "rails_helper"

RSpec.describe "Setup accountant read-after-save sources" do
  it "visual-identity setup Contador is cadastro or leitura" do
    text = Rails.root.join(".specs/features/visual-identity/design.md").read
    section = text.split("### `setup` — `GET /setup`", 2).last.split("### `month` —", 2).first

    expect(section).not_to include("Id fiscal")
    expect(section).not_to include("Destino do pacote")
    expect(section).to include("CPF/CNPJ (preencher apenas números)")
    expect(section).to include("Email para envio")
    expect(section).to include("cadastro")
    expect(section).to include("presentation name")
    expect(section).to include("Editar")
    expect(section).to include("read-only")
    expect(section).to include("CPF/CNPJ")
    expect(section).to include("Salvar arquivo")
    expect(section).to include("#81")
    expect(section).to include("Arquivo do pacote")
  end
end
