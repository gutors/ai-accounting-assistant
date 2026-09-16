class CreateCoordinatorAccess < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.timestamps
    end

    create_table :accounts do |t|
      t.string :email, null: false
      t.string :google_uid
      t.timestamps
    end
    add_index :accounts, :email, unique: true
    add_index :accounts, :google_uid, unique: true, where: "google_uid IS NOT NULL"

    create_table :accesses do |t|
      t.references :account, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.string :kind, null: false
      t.timestamps
    end
    add_index :accesses, [ :account_id, :organization_id ], unique: true

    create_table :invites do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :email, null: false
      t.string :kind, null: false
      t.timestamps
    end
    add_index :invites, [ :organization_id, :email ], unique: true
  end
end
