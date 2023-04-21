class FixSpellingErrorsInOldreportsTable < ActiveRecord::Migration[7.0]
  def change
    rename_column :oldreports, :narative, :narrative
    rename_column :oldreports, :suspension_duraction, :suspension_duration
    rename_column :oldreports, :violaiton_number, :violation_number
  end
end
