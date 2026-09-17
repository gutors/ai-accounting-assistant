class AddClosedToMonths < ActiveRecord::Migration[8.1]
  def change
    add_column :months, :closed, :boolean, null: false, default: false
    add_column :months, :month_folder_id, :string
  end
end
