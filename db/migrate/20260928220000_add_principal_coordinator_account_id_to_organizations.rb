class AddPrincipalCoordinatorAccountIdToOrganizations < ActiveRecord::Migration[8.1]
  def up
    add_reference :organizations, :principal_coordinator_account,
      foreign_key: { to_table: :accounts, on_delete: :restrict },
      null: true

    execute <<~SQL.squish
      UPDATE organizations
      SET principal_coordinator_account_id = sub.account_id
      FROM (
        SELECT DISTINCT ON (organization_id) organization_id, account_id
        FROM accesses
        WHERE kind = 'coordinator'
        ORDER BY organization_id, created_at ASC, id ASC
      ) sub
      WHERE organizations.id = sub.organization_id
    SQL

    change_column_null :organizations, :principal_coordinator_account_id, false
  end

  def down
    remove_foreign_key :organizations, column: :principal_coordinator_account_id
    remove_index :organizations, :principal_coordinator_account_id
    remove_column :organizations, :principal_coordinator_account_id
  end
end
