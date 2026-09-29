require "rails_helper"
require Rails.root.join("db/migrate/20260928220000_add_principal_coordinator_account_id_to_organizations.rb")

RSpec.describe "AddPrincipalCoordinatorAccountIdToOrganizations" do
  self.use_transactional_tests = false

  it "backfill sets principal to earliest coordinator Access then the column is not null" do
    conn = ActiveRecord::Base.connection
    migration = AddPrincipalCoordinatorAccountIdToOrganizations.new

    truncate_product_tables
    ActiveRecord::Migration.suppress_messages { migration.down } if conn.column_exists?(:organizations, :principal_coordinator_account_id)
    Organization.reset_column_information

    now = Time.utc(2026, 9, 1, 12, 0, 0)
    later = Time.utc(2026, 9, 2, 12, 0, 0)
    tie = Time.utc(2026, 9, 3, 12, 0, 0)

    early = insert_account(conn, "early@exemplo.org")
    late = insert_account(conn, "late@exemplo.org")
    tie_b = insert_account(conn, "tie-b@exemplo.org")
    tie_a = insert_account(conn, "tie-a@exemplo.org")
    norte = insert_organization(conn, "ONG Norte")
    sul = insert_organization(conn, "ONG Sul")
    insert_access(conn, late, norte, later)
    insert_access(conn, early, norte, now)
    insert_access(conn, tie_b, sul, tie)
    insert_access(conn, tie_a, sul, tie)

    ActiveRecord::Migration.suppress_messages { migration.up }
    Organization.reset_column_information

    norte_principal = conn.select_value(
      "SELECT principal_coordinator_account_id FROM organizations WHERE id = #{norte}"
    ).to_i
    sul_principal = conn.select_value(
      "SELECT principal_coordinator_account_id FROM organizations WHERE id = #{sul}"
    ).to_i
    expect(norte_principal).to eq(early)
    expect(sul_principal).to eq(tie_b)
    column = conn.columns(:organizations).find { |item| item.name == "principal_coordinator_account_id" }
    expect(column.null).to be(false)
  ensure
    conn = ActiveRecord::Base.connection
    migration = AddPrincipalCoordinatorAccountIdToOrganizations.new
    unless conn.column_exists?(:organizations, :principal_coordinator_account_id)
      ActiveRecord::Migration.suppress_messages { migration.up }
    end
    Organization.reset_column_information
    truncate_product_tables
  end

  def insert_account(conn, email)
    conn.select_value(<<~SQL).to_i
      INSERT INTO accounts (email, created_at, updated_at)
      VALUES (#{conn.quote(email)}, NOW(), NOW())
      RETURNING id
    SQL
  end

  def insert_organization(conn, name)
    conn.select_value(<<~SQL).to_i
      INSERT INTO organizations (name, created_at, updated_at)
      VALUES (#{conn.quote(name)}, NOW(), NOW())
      RETURNING id
    SQL
  end

  def insert_access(conn, account_id, organization_id, created_at)
    conn.select_value(<<~SQL).to_i
      INSERT INTO accesses (account_id, organization_id, kind, created_at, updated_at)
      VALUES (#{account_id}, #{organization_id}, 'coordinator', #{conn.quote(created_at)}, #{conn.quote(created_at)})
      RETURNING id
    SQL
  end
end
