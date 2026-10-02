require "rails_helper"

RSpec.describe "Invite kind and mail status sources" do
  it "visual-identity design.md home Convites pendentes names kind and last delivery" do
    text = Rails.root.join(".specs/features/visual-identity/design.md").read
    home = text.split("### `home` — `GET /` (coordinator)", 2).last.split("### `home` — `GET /` (submitter)", 2).first

    expect(home).to include("Convites pendentes")
    expect(home).to include("Coordenador")
    expect(home).to include("Submitter")
    expect(home).to include("enviado")
    expect(home).to include("falhou envio do e-mail")
    expect(home).to match(/Reenviar e-mail\s+Cancelar/)
  end

  it "administration-list home invites names per-invite copy not Meses notice" do
    text = Rails.root.join(".design/administration-list.md").read
    section = text.split("## Screen `home` invites", 2).last.split("## Mail words", 2).first
    invite_resend = text.lines.find { |line| line.include?("| Invite resend |") }

    expect(section).to include("Coordenador")
    expect(section).to include("Submitter")
    expect(section).to include("enviado")
    expect(section).to include("falhou envio do e-mail")
    expect(section).to include("Reenviar e-mail")
    expect(section).to include("Cancelar")
    expect(invite_resend).to be_present
    expect(invite_resend).not_to include("The failure notice sits under `Meses`")
  end
end
