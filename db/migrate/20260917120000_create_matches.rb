class CreateMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :matches do |t|
      t.references :month, null: false, foreign_key: true
      t.text :observation
      t.timestamps
    end

    add_reference :payments, :match, foreign_key: true
    add_column :payments, :document_exception_kind, :string
    add_check_constraint :payments, "match_id IS NULL OR document_exception_kind IS NULL",
      name: "payments_match_xor_document_exception"

    add_reference :supporting_documents, :match, foreign_key: true
    add_reference :supporting_documents, :month, foreign_key: true
  end
end
