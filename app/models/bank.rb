class Bank < ApplicationRecord
  CATALOG = [
    { presentation_name: "Banco do Brasil", compe: "001", ispb: "00000000" },
    { presentation_name: "PagBank/PagSeguro", compe: "290", ispb: "08561701" },
    { presentation_name: "Caixa", compe: "104", ispb: "00360305" },
    { presentation_name: "Itaú", compe: "341", ispb: "60701190" },
    { presentation_name: "Bradesco", compe: "237", ispb: "60746948" },
    { presentation_name: "Santander", compe: "033", ispb: "90400888" },
    { presentation_name: "Sicredi", compe: "748", ispb: "01181521" },
    { presentation_name: "Sicoob", compe: "756", ispb: "02038232" },
    { presentation_name: "Nubank", compe: "260", ispb: "18236120" },
    { presentation_name: "Inter", compe: "077", ispb: "00416968" },
    { presentation_name: "Banrisul", compe: "041", ispb: "92702067" },
    { presentation_name: "Unicred", compe: "136", ispb: "00315557" }
  ].freeze

  has_many :bank_accounts, dependent: :restrict_with_exception

  validates :presentation_name, presence: true
  validates :compe, presence: true, uniqueness: true
  validates :ispb, presence: true, uniqueness: true

  def self.seed_catalog!
    CATALOG.each do |entry|
      record = find_or_initialize_by(compe: entry[:compe])
      record.update!(presentation_name: entry[:presentation_name], ispb: entry[:ispb])
    end
  end

  def self.ordered_catalog
    order(:compe)
  end
end
