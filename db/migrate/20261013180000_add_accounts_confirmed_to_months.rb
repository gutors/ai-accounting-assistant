class AddAccountsConfirmedToMonths < ActiveRecord::Migration[8.1]
  BACKFILL_SQL = <<~SQL
    UPDATE months
    SET accounts_confirmed = TRUE
    WHERE closed = TRUE
       OR EXISTS (
         SELECT 1 FROM bank_statements
         WHERE bank_statements.month_id = months.id
       )
  SQL

  def up
    add_column :months, :accounts_confirmed, :boolean, null: false, default: false
    execute BACKFILL_SQL
  end

  def down
    remove_column :months, :accounts_confirmed
  end
end
