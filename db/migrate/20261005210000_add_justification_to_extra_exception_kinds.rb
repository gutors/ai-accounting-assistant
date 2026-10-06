class AddJustificationToExtraExceptionKinds < ActiveRecord::Migration[8.1]
  def up
    add_column :extra_exception_kinds, :justification, :text
    execute <<~SQL.squish
      UPDATE extra_exception_kinds
      SET justification = 'Isento de documento de suporte.'
      WHERE justification IS NULL
    SQL
    change_column_null :extra_exception_kinds, :justification, false
  end

  def down
    remove_column :extra_exception_kinds, :justification
  end
end
