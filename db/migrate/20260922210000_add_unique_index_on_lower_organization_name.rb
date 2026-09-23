class AddUniqueIndexOnLowerOrganizationName < ActiveRecord::Migration[8.1]
  def change
    add_index :organizations, "lower((name)::text)",
      unique: true, name: "index_organizations_on_lower_name"
  end
end
