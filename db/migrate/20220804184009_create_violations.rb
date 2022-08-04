class CreateViolations < ActiveRecord::Migration[7.0]
  def change
    create_table :violations do |t|
      t.string :incident_id
      t.string :patron_id
      t.string :description

      t.timestamps
    end
  end
end
