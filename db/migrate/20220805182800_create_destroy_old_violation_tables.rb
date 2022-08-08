class CreateDestroyOldViolationTables < ActiveRecord::Migration[7.0]
  def up
    drop_table :violations
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
