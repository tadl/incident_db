class AddViolationFormatToIncidents < ActiveRecord::Migration[7.2]
  def change
    add_column :incidents, :violation_format, :string, null: false, default: "legacy"
  end
end
