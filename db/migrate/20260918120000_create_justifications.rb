class CreateJustifications < ActiveRecord::Migration[8.1]
  def change
    create_table :justifications do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.bigint :amount_cents, null: false
      t.timestamps
    end

    add_reference :supporting_documents, :justification, foreign_key: true
  end
end
