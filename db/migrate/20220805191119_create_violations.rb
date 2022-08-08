class CreateViolations < ActiveRecord::Migration[7.0]
  def change
    create_table :violations do |t|
      t.string :desciption
      t.belongs_to :patron, null: false, foreign_key: true
      t.belongs_to :incident, null: false, foreign_key: true

      t.timestamps
    end
  end
end
