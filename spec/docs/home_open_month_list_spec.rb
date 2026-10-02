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
end
