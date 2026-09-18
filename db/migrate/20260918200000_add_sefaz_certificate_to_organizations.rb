class AddSefazCertificateToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :sefaz_pkcs12_ciphertext, :text
    add_column :organizations, :sefaz_passphrase_ciphertext, :text
    add_column :organizations, :sefaz_titular_cnpj, :string
    add_column :organizations, :sefaz_not_after, :date
  end
end
