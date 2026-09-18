class AddChaveAndFieldsOriginToSupportingDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :supporting_documents, :chave, :string
    add_column :supporting_documents, :fields_origin, :string
  end
end
