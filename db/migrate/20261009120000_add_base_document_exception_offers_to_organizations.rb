class AddBaseDocumentExceptionOffersToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :bank_fee_exception_active, :boolean, null: false, default: true
    add_column :organizations, :accountant_fee_exception_active, :boolean, null: false, default: true
  end
end
