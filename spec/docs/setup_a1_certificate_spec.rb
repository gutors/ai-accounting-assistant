require "rails_helper"

RSpec.describe "Setup A1 certificate sources" do
  it "visual-identity setup certificate is A1 heading and folded install" do
    text = Rails.root.join(".specs/features/visual-identity/design.md").read
    section = text.split("### `setup` — `GET /setup`", 2).last.split("### `month` —", 2).first

    expect(section).not_to include("Certificado SEFAZ")
    expect(section).not_to include("Nenhum certificado")
    expect(section).to include("Certificado Digital A1 - Para consulta na SEFAZ")
    expect(section).to include("Não há certificado A1 instalado. Use Instalar certificado.")
    expect(section).to include("details")
    expect(section).to include("Instalar certificado")
    expect(section).to include("Remover")
    expect(section).to include("quiet, margem")
    expect(section).to include("titular")
    expect(section).to include("Válido até")
    expect(section).to include("Expirado em")
    expect(section).to include("<summary>")
  end
end
