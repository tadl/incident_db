class CreateIncidents < ActiveRecord::Migration[7.0]
  def change
    create_table :incidents do |t|
      t.string :title
      t.datetime :date_of
      t.string :location
      t.string :department
      t.string :description
      t.integer :primary_pic

      t.timestamps
    end
  end
end
