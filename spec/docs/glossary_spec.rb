require "rails_helper"

RSpec.describe "GLOSSARY" do
  it "GLOSSARY defines Accounts confirmation" do
    text = Rails.root.join("GLOSSARY.md").read
    entry = text.split("**Accounts confirmation**:", 2).last.split("**Bank statement**:", 2).first

    expect(text).to include("**Accounts confirmation**:")
    expect(entry).to include("persisted agreement")
    expect(entry).to include("Month")
    expect(entry).to include("statement set is ready to work as movements")
    expect(entry).to include("those three lists stay off the month page")
    expect(entry).to include("there is no movement to match")
    expect(entry).to include("upload still writes the BankStatement")
    expect(entry).to include("replacing a statement does not clear it")
    expect(entry).to include("not session")
    expect(entry).to include("Presente (per-account file)")
    expect(entry).to include("close-for-send")
  end
end
