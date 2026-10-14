require "rails_helper"

RSpec.describe "Home open month list sources" do
  it "visual-identity home wireframe uses a month select" do
    text = Rails.root.join(".specs/features/visual-identity/design.md").read
    section = text.split("### `home` — `GET /` (coordinator)", 2).last.split("### `home` — `GET /` (submitter)", 2).first

    expect(section).not_to include("Mês  [____]  [ Abrir mês ]")
    expect(section).to include("select")
    expect(section).to include("today − 12")
    expect(section).to include("today + 12")
    expect(section).to include("previous calendar month selected")
    expect(section).to include("year_month")
    expect(section).to include("Aberto")
    expect(section).to include("Fechado")
  end

  it "visual-identity home Meses has Excluir on never-sent Aberto rows" do
    text = Rails.root.join(".specs/features/visual-identity/design.md").read
    section = text.split("### `home` — `GET /` (coordinator)", 2).last.split("### `home` — `GET /` (submitter)", 2).first

    expect(section).to include("Mês | AAAA-MM | Status")
    expect(section).to include("last action")
    expect(section).to include("Excluir")
    expect(section).to include("never been closed-for-send")
    expect(section).to include("Excluir este fechamento?")
    expect(section).to include("Fechado")
    expect(section).to include("reopened")
    expect(section).to include("omit")
  end
end
