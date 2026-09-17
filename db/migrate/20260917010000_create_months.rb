class CreateMonths < ActiveRecord::Migration[8.1]
  def change
    create_table :months do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :year_month, null: false
      t.timestamps
    end
    add_index :months, [ :organization_id, :year_month ], unique: true
  end
end
