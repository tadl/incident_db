class CreatePatrons < ActiveRecord::Migration[7.0]
  def change
    create_table :patrons do |t|
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.string :gender
      t.boolean :no_name
      t.boolean :no_address
      t.string :address
      t.string :city
      t.string :state
      t.integer :zip
      t.string :alias
      t.string :description
      t.string :notes

      t.timestamps
    end
  end
end
