require "rails_helper"

RSpec.describe "Action result toast sources" do
  it "visual-identity design.md names Toast and Motion timeout" do
    text = Rails.root.join(".specs/features/visual-identity/design.md").read

    expect(text).to include("### Toast")
    expect(text).to include("header")
    expect(text).to include("main")
    expect(text).to include("caixa")
    expect(text).to include("margem")
    expect(text).to include("5000")
    expect(text).to include("Fechar")
    expect(text).not_to include("<details> opening is the only state change")
    expect(text).to match(/toast timeout/i)
  end

  it "visual-identity design.md states the success copy rules" do
    text = Rails.root.join(".specs/features/visual-identity/design.md").read
    toast = text.split("### Toast", 2).last.split("### Empty state", 2).first

    expect(toast).to include("app/models/action_toast.rb")
    expect(toast).to include("names the object")
    expect(toast).to include("40 characters")
    expect(toast).to include("format_reais")
    expect(toast).to include("No `Pronto.`")
  end

  it "adr 0009 records where action-result copy lives" do
    text = Rails.root.join("docs/adr/0009-action-result-copy.md").read

    expect(text).to include("app/models/action_toast.rb")
    expect(text).to include("redirect_success")
    expect(text).to include("Rejected")
  end

  it "administration-list home invites names the error toast" do
    text = Rails.root.join(".design/administration-list.md").read
    section = text.split("## Screen `home` invites", 2).last.split("## Mail words", 2).first

    expect(section).to include("error toast")
    expect(section).to include("#78")
    expect(section).not_to include("A failed send shows the notice under the `Meses` title")
    expect(section).not_to include("`Cancelar` does not set or clear it")
  end
end
