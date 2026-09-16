require "rails_helper"

RSpec.describe Bank, type: :model do
  it "catalog is the twelve institutions from COMPE 001 through 756" do
    expected = [
      [ "Banco do Brasil", "001", "00000000" ],
      [ "PagBank/PagSeguro", "290", "08561701" ],
      [ "Caixa", "104", "00360305" ],
      [ "Itaú", "341", "60701190" ],
      [ "Bradesco", "237", "60746948" ],
      [ "Santander", "033", "90400888" ],
      [ "Sicredi", "748", "01181521" ],
      [ "Sicoob", "756", "02038232" ],
      [ "Nubank", "260", "18236120" ],
      [ "Inter", "077", "00416968" ],
      [ "Banrisul", "041", "92702067" ],
      [ "Unicred", "136", "00315557" ]
    ]

    expect(Bank.count).to eq(12)
    expected.each do |name, compe, ispb|
      bank = Bank.find_by!(compe: compe)
      expect(bank.presentation_name).to eq(name)
      expect(bank.ispb).to eq(ispb)
    end
  end

  it "rejects a second Bank for the same COMPE" do
    duplicate = Bank.new(presentation_name: "Outro BB", compe: "001", ispb: "11111111")

    expect(duplicate).not_to be_valid
  end

  it "rejects a second Bank for the same ISPB" do
    duplicate = Bank.new(presentation_name: "Outro", compe: "999", ispb: "00000000")

    expect(duplicate).not_to be_valid
  end
end
