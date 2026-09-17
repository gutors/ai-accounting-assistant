class CreateSupportingDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :supporting_documents do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :kind, null: false
      t.bigint :amount_cents, null: false
      t.date :document_on, null: false
      t.string :payee, null: false
      t.text :observation
      t.timestamps
    end
    add_index :supporting_documents, [ :organization_id, :document_on ]
  end
end
