class CreateSuspensions < ActiveRecord::Migration[7.0]
  def change
    create_table :suspensions do |t|
      t.belongs_to :patron, null: false, foreign_key: true
      t.belongs_to :incident, null: false, foreign_key: true
      t.date :until
      t.boolean :letter_sent
      t.boolean :call_police

      t.timestamps
    end
  end
end
