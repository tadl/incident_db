class ChangeAliasToKnownAs < ActiveRecord::Migration[7.0]
  def change
    rename_column :patrons, :alias, :known_as
  end
end
