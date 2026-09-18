class CreateExtraExceptionKinds < ActiveRecord::Migration[8.1]
  def change
    create_table :extra_exception_kinds do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.boolean :active, default: true, null: false
      t.timestamps
    end

    add_index :extra_exception_kinds, "organization_id, lower((name)::text)",
      unique: true, name: "index_extra_exception_kinds_on_org_id_and_lower_name"

    add_reference :payments, :extra_exception_kind, foreign_key: { on_delete: :restrict }

    remove_check_constraint :payments, "match_id IS NULL OR document_exception_kind IS NULL",
      name: "payments_match_xor_document_exception"
    add_check_constraint :payments,
      "(match_id IS NULL OR document_exception_kind IS NULL) AND " \
      "(match_id IS NULL OR extra_exception_kind_id IS NULL) AND " \
      "(document_exception_kind IS NULL OR extra_exception_kind_id IS NULL)",
      name: "payments_match_xor_document_exception"
  end
end
