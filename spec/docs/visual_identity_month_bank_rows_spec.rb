require "rails_helper"

RSpec.describe "Visual identity month bank rows" do
  it "visual-identity month Contas bancarias uses Situacao and Documentos" do
    design = Rails.root.join(".specs/features/visual-identity/design.md").read
    month = design.split("### `month` — `GET /months/:year_month`", 2).last.split("### `documents` —", 2).first
    checks = Rails.root.join(".specs/features/visual-identity/checks.md").read

    expect(month).to include("Documentos")
    expect(month).to include("Pdf {filename}")
    expect(month).to include("Planilha {filename}")
    expect(month).to include("Incluir extrato")
    expect(month).to match(/Situação `Presente`\s+or `Falta`/)
    expect(month).to include("no filenames")
    expect(month).not_to include("when absent the upload form is inline")
    expect(month).not_to include("`Presente` with the\n  two filenames in meta")
    expect(checks).to include("Envie a planilha")
    expect(checks).to include("absent statement folds the upload form under Incluir extrato")
    expect(checks).not_to include("its upload form has no `<details>` ancestor")
    expect(checks).not_to include("Envie o PDF e a planilha")
  end
end
