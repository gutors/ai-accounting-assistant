class CreateOrganizationCloseSetup < ActiveRecord::Migration[8.1]
  def change
    change_table :organizations, bulk: true do |t|
      t.string :accountant_presentation_name
      t.string :accountant_tax_id
      t.string :accountant_legal_name
      t.string :accountant_pix_key
      t.string :package_destination_email
      t.string :package_archive_url
      t.string :package_archive_folder_id
    end

    create_table :banks do |t|
      t.string :presentation_name, null: false
      t.string :compe, null: false
      t.string :ispb, null: false
      t.timestamps
    end
    add_index :banks, :compe, unique: true
    add_index :banks, :ispb, unique: true

    create_table :bank_accounts do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :bank, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.string :coordinates
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :bank_accounts, [ :organization_id, :name ], unique: true
    add_index :bank_accounts, [ :organization_id, :slug ], unique: true

    reversible do |dir|
      dir.up do
        Bank.reset_column_information
        Bank.seed_catalog!
      end
    end
  end
end
