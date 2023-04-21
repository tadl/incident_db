class AddViolationNumberToOldreports < ActiveRecord::Migration[7.0]
  def change
    add_column :oldreports, :violaiton_number, :string
  end
end
