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

  it "GLOSSARY Nota fiscal Chave de acesso SEFAZ consulta name uploaded XML models" do
    text = Rails.root.join("GLOSSARY.md").read
    nota = text.split("**Nota fiscal**:", 2).last.split("**Chave de acesso**:", 2).first
    chave = text.split("**Chave de acesso**:", 2).last.split("**SEFAZ consulta**:", 2).first
    sefaz = text.split("**SEFAZ consulta**:", 2).last.split("**SEFAZ certificate**:", 2).first

    expect(nota).to include("NF-e")
    expect(nota).to include("NFC-e")
    expect(nota).to include("NFCom (modelo 62)")
    expect(nota).to include("NF3e (modelo 66)")
    expect(nota).to include("national NFS-e")
    expect(nota).to include("authorized XML")
    expect(chave).to include("uploaded XML")
    expect(chave).to include("`Id`")
    expect(chave).to include("44")
    expect(chave).to include("50")
    expect(chave).to include("national NFS-e")
    expect(chave).to include("Typed chave")
    expect(chave).to include("photo decode remain 44")
    expect(sefaz).to include("NF-e")
    expect(sefaz).to include("NFC-e")
    expect(sefaz).not_to include("NFCom")
    expect(sefaz).not_to include("NF3e")
    expect(sefaz).not_to include("NFS-e")
  end
end
