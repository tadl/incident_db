class FixColumnName < ActiveRecord::Migration[7.0]
  def change
    rename_column :violations, :desciption, :description
  end
end
