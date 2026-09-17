class CreateBankStatements < ActiveRecord::Migration[8.1]
  def change
    create_table :bank_statements do |t|
      t.references :month, null: false, foreign_key: true
      t.references :bank_account, null: false, foreign_key: true
      t.timestamps
    end
    add_index :bank_statements, [ :month_id, :bank_account_id ], unique: true

    create_table :inflows do |t|
      t.references :bank_statement, null: false, foreign_key: true
      t.date :occurred_on, null: false
      t.bigint :amount_cents, null: false
      t.text :history, null: false
      t.timestamps
    end
    add_index :inflows, [ :bank_statement_id, :occurred_on ]

    create_table :payments do |t|
      t.references :bank_statement, null: false, foreign_key: true
      t.date :occurred_on, null: false
      t.bigint :amount_cents, null: false
      t.text :history, null: false
      t.timestamps
    end
    add_index :payments, [ :bank_statement_id, :occurred_on ]
  end
end
