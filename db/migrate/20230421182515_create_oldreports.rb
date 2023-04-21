class CreateOldreports < ActiveRecord::Migration[7.0]
  def change
    create_table :oldreports do |t|
      t.string :legacy_id
      t.date :date_of
      t.time :time_of
      t.string :title
      t.string :patron_name
      t.string :patron_address
      t.string :description
      t.string :narative
      t.string :location
      t.time :date_entered
      t.string :submitted_by
      t.string :suspension
      t.string :suspension_duraction
      t.string :a_violations
      t.string :b_violations

      t.timestamps
    end
  end
end
