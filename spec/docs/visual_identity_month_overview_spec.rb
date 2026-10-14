require "rails_helper"

RSpec.describe "Visual identity month overview" do
  it "visual-identity month is close status folds chips Documento no Resolver" do
    design = Rails.root.join(".specs/features/visual-identity/design.md").read
    month = design.split("### `month` — `GET /months/:year_month`", 2).last.split("### `", 2).first
    source = Rails.root.join(".design/month-overview.md").read

    expect(month).to include("Voltar para Início")
    expect(month).to include("first in `<main>`")
    expect(month).to include("only while open and")
    expect(month).to include("confirmed")
    expect(month).to include(".ds-btn-secondary")
    expect(month).to include("under `YYYY-MM`")
    expect(month).to include("only `Restaurar pasta` and `Reabrir`")
    expect(month).to include("details open class=\"month-fold\"")
    expect(month).to include("Recebimentos")
    expect(month).to include("last")
    expect(month).to include("Todas")
    expect(month).to include("?bank_account_id=")
    expect(month).to include("Pagamentos and Recebimentos only")
    expect(month).to include("pool unfiltered")
    expect(month).to include("404")
    expect(month).to include("Documento")
    expect(month).to include("no `Resolver`")
    expect(month).to include("no N:1 fold")
    expect(month).to include("Sugestão")
    expect(month).to include("Foto")
    expect(month).to include("url_for")
    expect(month).to include("form=\"close-month\"")
    expect(month).to include("Devolver")
    expect(source).to include("Voltar para Início")
    expect(source).to include("Livro com bloqueio")
  end
end
