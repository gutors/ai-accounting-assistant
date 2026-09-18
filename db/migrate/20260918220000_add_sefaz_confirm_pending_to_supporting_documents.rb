class AddSefazConfirmPendingToSupportingDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :supporting_documents, :sefaz_confirm_pending, :boolean, default: false, null: false
  end
end
