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

  it "visual-identity month confirms accounts before movements" do
    design = Rails.root.join(".specs/features/visual-identity/design.md").read
    month = design.split("### `month` — `GET /months/:year_month`", 2).last.split("### `documents` —", 2).first
    checks = Rails.root.join(".specs/features/visual-identity/checks.md").read

    expect(month).to include("accounts_confirmed")
    expect(month).to include("Insira os extratos das contas bancárias com as quais deseja realizar o fechamento.")
    expect(month).to include("not the missing-document count")
    expect(month).to include("Confirmar contas para fechamento")
    expect(month).to include("Presente")
    expect(month).to include("Falta")
    expect(month).to include("margem")
    expect(month).to include("ledger name order")
    expect(month).to include("two-column ledger (`Nome`, `Situação`)")
    expect(month).to include("Iniciar fechamento")
    expect(month).to include("Recebimentos")
    expect(month).to include("Pagamentos")
    expect(month).to include("Documentos sem casamento")
    expect(month).to include("are omitted")
    expect(month).to include("After confirmation (or while closed)")
    expect(month).to include("the confirm step is absent")
    expect(checks).to include("Insira os extratos das contas bancárias com as quais deseja realizar o fechamento.")
    expect(checks).to include("Confirmar contas para fechamento")
    expect(checks).to include("Iniciar fechamento")
    expect(checks).to include("Recebimentos")
    expect(checks).to include("Pagamentos")
    expect(checks).to include("Documentos sem casamento")
    expect(checks).to include("are omitted")
    expect(checks).to include("after confirmation or while closed")
  end

  it "visual-identity month disables confirm without a spreadsheet" do
    design = Rails.root.join(".specs/features/visual-identity/design.md").read
    month = design.split("### `month` — `GET /months/:year_month`", 2).last.split("### `documents` —", 2).first

    expect(month).to include("Iniciar fechamento")
    expect(month).to include("disabled")
    expect(month).to include("Inclua o extrato planilha de pelo menos uma conta bancária.")
    expect(month).to include("at least one Presente")
    expect(month).to include("mixed Falta allowed")
    expect(month).to include("Close-for-send still requires every active account’s statement")
  end

  it "visual-identity matches screen sticky band next suggestion and day month dates" do
    design = Rails.root.join(".specs/features/visual-identity/design.md").read
    matches = design.split("### `matches` — `GET /months/:year_month/matches`", 2).last.split("### `", 2).first
    month = design.split("### `month` — `GET /months/:year_month`", 2).last.split("### `", 2).first

    expect(matches).to include("maio de 2026")
    expect(matches).to include("2026-05")
    expect(matches).to include("Voltar ao mês")
    expect(matches).to include("no `Fechar para envio`")
    expect(matches).to include("no stamp")
    expect(matches).to include("Todas")
    expect(matches).to include("?bank_account_id=")
    expect(matches).to include("Pagamentos only")
    expect(matches).to include("margem")
    expect(matches).to include("1100px")
    expect(matches).to include("Pagamentos wider")
    expect(matches).to include("stacked")
    expect(matches).to include("Pagamentos first")
    expect(matches).to include("checkbox")
    expect(matches).to include("×")
    expect(matches).to include("no `Resolver`")
    expect(matches).to include("Nenhum documento sem casamento")
    expect(matches).to include("Soma igual")
    expect(matches).to include("Documentos somam menos")
    expect(matches).to include("Documentos somam mais")
    expect(matches).to include("stay after confirm")
    expect(matches).to include("Próxima sugestão")
    expect(matches).to include("casar com")
    expect(matches).to include("11/05")
    expect(matches).to include("oldest")
    expect(matches).to include("click equal")
    expect(matches).to include("no `Casar`")
    expect(matches).to include("Sugestão {payees}")
    expect(matches).to include("Sugestão de exceção")
    expect(month).to include("Casar pagamentos")
    expect(month).to include("only while open and")
    expect(month).to include("confirmed")
  end
end
