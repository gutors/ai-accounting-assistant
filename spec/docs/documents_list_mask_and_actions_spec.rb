require "rails_helper"

RSpec.describe "Documents list mask and actions sources" do
  it "visual-identity documents Sem mes is Data Favorecido Tipo Valor Acoes" do
    text = Rails.root.join(".specs/features/visual-identity/design.md").read
    section = text.split("### `documents`", 2).last.split("## Responsive", 2).first

    expect(section).to include("Data | Favorecido | Tipo | Valor | Ações")
    expect(section).to include("filenames, chave")
    expect(section).to include("observation, month status as meta under payee")
    expect(section).to include("Excluir` in Ações, not inside the edit panel")
    expect(section).to include("Kind is not a meta line under payee")
    expect(section).to include("Editar does not offer a control that changes Tipo")
  end
end
